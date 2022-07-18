pragma solidity >= 0.8 .0;

contract Metadata {
    address public Dev;
    string a = '<svg xmlns="http://www.w3.org/2000/svg" width="830" height="830" style="-webkit-user-select: none;-moz-user-select: none;-ms-user-select: none;user-select: none;"><defs><radialGradient id="rgrad" cx="50%" cy="50%" r="40%">';
    string b = '</radialGradient></defs><rect x="0" y="0" width="100%" height="100%" fill="url(#rgrad)"/><g dx="20" dy="0" transform="scale(23)" style="opacity:0.9"><g><animate attributeName="fill" values="';
    string c = '" dur="42s" repeatCount="indefinite"/><path d="M5 16c0-4-5-3-4 1s3 5 3 5l1-6zm26 0c0-4 5-3 4 1s-3 5-3 5l-1-6z"/><path d="M32.65 21.736c0 10.892-4.691 14.087-14.65 14.087S3.349 32.628 3.349 21.736 8.042.323 18 .323s14.65 10.521 14.65 21.413z"/></g> <path fill="#66757f" d="M27.567 23c1.49-4.458 2.088-7.312-.443-7.312H8.876c-2.532 0-1.933 2.854-.444 7.312C3.504 34.201 17.166 34.823 18 34.823S32.303 33.764 27.567 23z"/><g><animate attributeName="fill" values="';
    string d = '" dur="21s" repeatCount="indefinite"/><path d="M15 18.003a2 2 0 1 1-4 0c0-1.104.896-1 2-1s2-.105 2 1zm10 0a2 2 0 1 1-4 0c0-1.104.896-1 2-1s2-.105 2 1z"/></g><g><ellipse cx="15.572" cy="23.655" rx="1.428" ry="1"/><path d="M21.856 23.655c0 .553-.639 1-1.428 1s-1.429-.447-1.429-1 .639-1 1.429-1 1.428.448 1.428 1z"/></g><path fill="#99aab5" d="M21.02 21.04c-1.965-.26-3.02.834-3.02.834s-1.055-1.094-3.021-.834c-3.156.417-3.285 3.287-1.939 3.105.766-.104.135-.938 1.713-1.556s3.247.66 3.247.66 1.667-1.276 3.246-.659.947 1.452 1.714 1.556c1.346.181 1.218-2.689-1.94-3.106z"/><path fill="#31373d" d="M24.835 30.021c-1.209.323-3.204.596-6.835.596s-5.625-.272-6.835-.596c-3.205-.854-1.923-1.735 0-1.477s3.631.415 6.835.415 4.914-.156 6.835-.415 3.204.623 0 1.477z"/><path fill="#66757f"    d="M4.253 16.625c1.403-1.225-1.078-3.766-2.196-2.544-.341.373.921-.188 1.336 1.086.308.942.001 2.208.86 1.458zm27.493 0c-1.402-1.225 1.078-3.766 2.196-2.544.341.373-.921-.188-1.337 1.086-.306.942 0 2.208-.859 1.458z"/></g><rect y="750" width="100%" height="80" fill="#ffffff55"/><text x="25" y="810" style="font-size:4em;" font-family="monospace" textLength="775" lengthAdjust="spacingAndGlyphs">';
    string[] radMap = ["0", "10", "20", "30", "40", "50", "60", "70", "80", "90", "100"];

    function toHexColor(bytes memory _input) internal pure returns(string[] memory _output, string memory _list) {
        uint fill = ((_input.length * 2) / 6) + 1;
        _output = new string[](fill);
        bytes memory _base = "0123456789abcdef";
        uint j;
        uint k;
        uint _len = (_input.length / 6) * 6;
        bytes memory _hex = new bytes(6);
        for (uint i; i < _len; i++) {
            _hex[k * 2] = _base[uint8(_input[i]) / 16];
            _hex[k * 2 + 1] = _base[uint8(_input[i]) % 16];
            k++;
            if (k == 3) {
                _output[j] = string.concat(string(_hex));
                _list = string.concat(_list, "#", string(_hex), ";");
                j++;
                k = 0;
                _hex = new bytes(6);
            }
        }
        _list = string.concat(_list, "#",_output[0], ";");
        _output[fill - 1] = _output[0];
    }

    function image(uint id) internal view returns(string memory) {
        (string[] memory _arr, string memory _list) = toHexColor(abi.encodePacked(keccak256(abi.encodePacked(id))));
        string memory _stop;
        for (uint i = 0; i < 10; i++) {
            _stop = string.concat(_stop, '<stop offset="', radMap[i], '%" style="stop-color:#', _arr[i], ';"/>');
        }
        // <stop offset="100%"><animate attributeName="stop-color" values="#4b216c;#96deb6;#6b955e;#456077;#fb64cc;#fa152d;#595716;#17979d;#84472c;#863d0c;4b216c" dur="100s" repeatCount="indefinite"></animate></stop>
        _stop = string.concat(_stop, '<stop offset="100%"><animate attributeName="stop-color" values="', _list, '" dur="111s" repeatCount="indefinite"></animate></stop>');
        return string.concat("data:image/svg+xml;base64,", encode64(bytes(string.concat(a, _stop, b, _list, c, _list, d, toString(id), ".BoredENSYachtClub.eth</text></svg>"))));
    }

    function generate(uint id) public view returns(string memory) {
        string memory _name = string.concat(toString(id), ".BoredENSYachtClub.eth");
        return string.concat(
            'data:text/plain,{"name":"', _name, '",', 
            '"description":"1 of 10K Bored ENS Yacht Club Membership Card.",',
            '"external_url": "https://', _name, '.limo",',
            '"image":"', image(id), '",',
            attrib(id),      
            '}');
    }
    string[] NumList = ["Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten"];
    function attrib(uint id) internal view returns(string memory){
        string memory _pat;
        for(uint i = 10; i > 0; i--){
            if(id % i == 0){
                _pat = string.concat('"', NumList[i], '": true');
                break;
            }
        }
        return string.concat(
            (id <= 250) ? '"Alpha": true,' : (id >=9750) ? '"Omega" : true,' : "", 
            _pat
        );
    }

    function toString(uint value) internal pure returns(string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license 
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // Base64 
    // @author Brecht Devos - <[email protected]>
    // @notice Provides functions for encoding/decoding base64
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode64(bytes memory data) internal pure returns(string memory) {
        if (data.length == 0) return '';
        string memory table = TABLE_ENCODE;
        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        string memory result = new string(encodedLen + 32);

        assembly {
            mstore(result, encodedLen)
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 32)
            for {}
            lt(dataPtr, endPtr) {} {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }
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

    function DESTROY() public {
        require (msg.sender == Dev);
        selfdestruct(payable(msg.sender));
    }
    // add approve and fallback/receiver
}