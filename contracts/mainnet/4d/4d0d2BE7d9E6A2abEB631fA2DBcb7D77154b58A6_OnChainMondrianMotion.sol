// SPDX-License-Identifier: MIT

// ONCHAIN MONDRIAN MOTION                                                       
// www.nftmintclub.com

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

pragma solidity ^0.8.0;

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

pragma solidity ^0.8.0;

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

pragma solidity ^0.8.0;
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
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
}

pragma solidity ^0.8.0;
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

pragma solidity ^0.8.0;
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

pragma solidity ^0.8.0;

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/Context.sol
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


// File: @openzeppelin/contracts/token/ERC721/ERC721.sol
pragma solidity ^0.8.0;
/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
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

    // DEFINE THE PALETTES
    // sets of 5, 0 to 4, 5 to 9 etc
    string[] private palette = [
    '323232','C8C8C8','646464','FFFFFF','303030',
    '27E9B9','7534FE','9A6DFF','FFFFFF','303030',
    'E71A24','F2E610','1249FF','FFFFFF','303030',
    'FFCA50','FF7B52','FF58B8','FFFFFF','303030',
    'F99A70','64AFED','C52699','FFFFFF','303030',
    'FF640B','007BF9','D0D0D0','FFFFFF','303030',
    'A8A7A7','FF4740','E8175D','FFFFFF','303030',
    'E12D95','2F9599','F7DB4F','FFFFFF','303030',
    'C3FD74','547980','45ADA8','FFFFFF','303030',
    'C0C0C0','A523EC','F900B7','FFFFFF','303030',
    '8A5441','FAB55E','B4B8B9','FFFFFF','303030',
    'F527A1','9FCC18','717277','FFFFFF','303030',
    '43627A','147F91','238CBF','FFFFFF','303030',
    'FFEBE0','00C4E4','AA43CF','FFFFFF','303030',
    '492684','E6BC71','C0C0C0','FFFFFF','303030',
    'DCCCA3','824C71','4A2545','FFFFFF','303030',
    'FF01FB','02A9EA','FAFF00','FFFFFF','303030',
    'FF0022','41EAD4','B91372','FFFFFF','303030',
    'FE64A3','F6839C','F0B5B3','FFFFFF','303030',  
    'F3752B','F52F57','F79D5C','FFFFFF','303030',
    'B9929F','610F7F','ACB81E','FFFFFF','303030',
    'D30000','FF6600','FFF100','FFFFFF','303030',
	'EEDAA3','CFBE8D','404040','FFFFFF','303030',
	'D7CDCC','59656F','9C528B','FFFFFF','303030',
    '792359','D72483','FD3E81','FFFFFF','303030'];  

    bool public migrate = false;
    string public migrateAddress = "---";

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory output) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");  

        string memory seed = tokenId.toString();
        uint loopsUse = uint256(keccak256(abi.encodePacked(seed, "loopsUse"))) % (150 - 26) + 26;

        uint[] memory x1    = new uint[](loopsUse+10);
        uint[] memory y1    = new uint[](loopsUse+10);
        uint[] memory x2    = new uint[](loopsUse+10);
        uint[] memory y2    = new uint[](loopsUse+10);
   
        // choose the colours, this is done via an offset
        uint pP = uint256(keccak256(abi.encodePacked(seed, "paletteselection"))) % 25 * 5;

             // inital 4 
             x1[0] = 0;     y1[0] = 0;     x2[0] = 128;   y2[0] = 128;
             x1[1] = 128;   y1[1] = 0;     x2[1] = 256;   y2[1] = 128;
             x1[2] = 0;     y1[2] = 128;   x2[2] = 128;   y2[2] = 256;
             x1[3] = 128;   y1[3] = 128;   x2[3] = 256;   y2[3] = 256;

        uint lookup;  
        uint next;
        uint splitkeep;
        uint width;
        uint height;
        string memory istring;

        if (migrate == true)
        {
        output = string.concat('{"name": "OnChain Mondrian", "description": "This contract has been migrated to ',
        migrateAddress,'","image": "data:image/svg+xml;base64,',
        Base64.encode(bytes('<svg width="100%" height="100%" viewBox="0 0 1110 1110" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xml:space="preserve" style="fill-rule:evenodd;clip-rule:evenodd;stroke-linejoin:round;stroke-miterlimit:2;"><rect x="0" y="0" width="1110" height="1110"/><g><path d="M504.488,679.5l-62.817,-528l115.829,1.573l115.829,-1.573l-62.817,528l-106.024,0Z" style="fill:#fff;"/><circle cx="557.5" cy="860.5" r="87" style="fill:#fff;"/></g></svg>')),
        '"}'
        );
        output = Base64.encode(bytes(string(abi.encodePacked(output))));      
        output = string(abi.encodePacked('data:application/json;base64,', output));        
        return output;           
        }

        // make array of coordinates loop number of times
        for (uint256 i = 1; i < loopsUse; i++) 
        {  
            istring = i.toString();
            next = i + 3;  
            splitkeep = uint256(keccak256(abi.encodePacked(seed,istring))) % 4; 
            if (i < 25) { lookup = i - 1; }
            else
                {
                    lookup = uint256(keccak256(abi.encodePacked(seed, istring))) % i; 
                }

            if (splitkeep == 0)
            {
                        // vertical
                        x1[next] = (x1[lookup] + x2[lookup]) / 2;
                        x2[next] = x2[lookup];
                        y1[next] = y1[lookup];
                        y2[next] = y2[lookup];
            }
            else if (splitkeep == 1)
            {
                        // vertical
                        x2[next] = (x1[lookup] + x2[lookup]) / 2;
                        x1[next] = x1[lookup];
                        y1[next] = y1[lookup];
                        y2[next] = y2[lookup];
            }
            else if (splitkeep == 2)
            {
                        // horizontal
                        y1[next] = (y1[lookup] + y2[lookup]) / 2;
                        y2[next] = y2[lookup];
                        x1[next] = x1[lookup];
                        x2[next] = x2[lookup];
            }
            else
            {
                        // horizontal
                        y2[next] = (y1[lookup] + y2[lookup]) / 2;
                        y1[next] = y1[lookup];		
                        x1[next] = x1[lookup];
                        x2[next] = x2[lookup];
            }

            width = x2[next] - x1[next];
            height = y2[next] - y1[next];

            if (width < 5 || height < 5) {
                continue;
            }

            bytes32 kec = keccak256(bytes(istring));

                output = string.concat(output,
                '<rect id="a',
                splitkeep.toString(),
                '-',
                (uint256(kec) % 10).toString(),
                '" x="',
                x1[next].toString(),
                '" y="',
                y1[next].toString(),
                '" width="',
                width.toString(),
                '" height="',
                height.toString(),
                '" style="fill:#',
                palette[pP + uint256(kec) % 5],
                ';"/>');         
        
        }
            // wrap in headers and footers 
            string memory output2 = '<svg width="1024" height="1024" viewBox="0 0 256 256" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xml:space="preserve" xmlns:serif="http://www.serif.com/" style="fill-rule:evenodd;clip-rule:evenodd;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:1.5;" overflow="hidden">';

            // this adds the CSS for the animated versions
            output2 = string.concat(output2,'<style>@keyframes movex { from {transform: translatex(-100%);} to {transform: translatex(100%);}}@keyframes movey { from {transform: translatey(-100%);} to {transform: translatey(100%);}}#a0-0 { animation: movey 10.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a1-0 { animation: movey 21.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a2-0 { animation: movex 11.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a3-0 { animation: movex 22.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a0-1 { animation: movey 12.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a1-1 { animation: movey 23.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a2-1 { animation: movex 13.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a3-1 { animation: movex 24.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a0-2 { animation: movey 14.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a1-2 { animation: movey 25.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a2-2 { animation: movex 15.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a3-2 { animation: movex 26.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a0-3 { animation: movey 16.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a1-3 { animation: movey 27.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a2-3 { animation: movex 17.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a3-3 { animation: movex 28.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a0-4 { animation: movey 18.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a1-4 { animation: movey 29.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a2-4 { animation: movex 19.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a3-4 { animation: movex 30.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a0-5 { animation: movey 39.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a1-5 { animation: movey 31.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a2-5 { animation: movex 40.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a3-5 { animation: movex 32.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a0-6 { animation: movey 41.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a1-6 { animation: movey 33.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a2-6 { animation: movex 42.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a3-6 { animation: movex 34.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a0-7 { animation: movey 43.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a1-7 { animation: movey 35.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a2-7 { animation: movex 44.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a3-7 { animation: movex 36.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a0-8 { animation: movey 45.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a1-8 { animation: movey 37.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a2-8 { animation: movex 46.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a3-8 { animation: movex 38.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a0-9 { animation: movey 47.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a1-9 { animation: movey 39.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a2-9 { animation: movex 48.0s infinite linear; animation-direction: alternate; transform-origin: center;}#a3-9 { animation: movex 40.0s infinite linear; animation-direction: alternate; transform-origin: center;}</style>');

            output2 = string.concat(output2,
            '<rect x="0" y="0" width="256" height="128" style="fill:#',
            palette[pP],
            ';stroke:#000;stroke-width:0.5px;"/>',
            '<rect x="0" y="128" width="256" height="128" style="fill:#',
            palette[pP + 1],
            ';stroke:#000;stroke-width:0.5px;"/>',
            '<g style="stroke:#000;stroke-width:0.5px;">');

            output2 = string.concat(output2,output,'</g><rect x="0" y="0" width="256" height="256" style="fill:none;stroke:#000;stroke-width:2.0px;"/></svg>');
           
            // Generate the metadata
            string[] memory mA = new string[](2); 

            if (loopsUse > 125) {
                mA[0] = "Very High";
            } else if (loopsUse > 100) {
                mA[0] = "High";
            } else if (loopsUse > 75) {
                mA[0] = "Medium";
            } else if (loopsUse > 50) {
                mA[0] = "Low";
            } else if (loopsUse > 20) {
                mA[0] = "Very Low";
            }

            if (pP == 0)        { mA[1] = "Monochrome"; }
            else if (pP == 5)   { mA[1] = "Fresh"; }
            else if (pP == 10)  { mA[1] = "Mondrian"; }
            else if (pP == 15)  { mA[1] = "Beach"; }
            else if (pP == 20)  { mA[1] = "Pudding"; }
            else if (pP == 25)  { mA[1] = "Sharp"; }
            else if (pP == 30)  { mA[1] = "Sunset"; }
            else if (pP == 35)  { mA[1] = "Party"; }
            else if (pP == 40)  { mA[1] = "Organic"; }
            else if (pP == 45)  { mA[1] = "Vivid"; }
            else if (pP == 50)  { mA[1] = "Coco"; }
            else if (pP == 55)  { mA[1] = "Epic"; }
            else if (pP == 60)  { mA[1] = "Glacier"; }
            else if (pP == 65)  { mA[1] = "Miracle"; }
            else if (pP == 70)  { mA[1] = "Opulent"; }
            else if (pP == 75)  { mA[1] = "Raisin"; }
            else if (pP == 80)  { mA[1] = "Punk"; }
            else if (pP == 85)  { mA[1] = "Gelato"; }
            else if (pP == 90)  { mA[1] = "Passion"; }
            else if (pP == 95)  { mA[1] = "Trifle"; }
            else if (pP == 100)  { mA[1] = "Poison"; }
            else if (pP == 105)  { mA[1] = "Inferno"; }
            else if (pP == 110)  { mA[1] = "Lusso"; }
            else if (pP == 115)  { mA[1] = "Haze"; }
            else  { mA[1] = "Shocking"; }
        
        output2 = string.concat('{"name": "OnChain Mondrian: ',
        seed,
        '", "description": "',
        'On-chain Mondrian Motion is an NFT collection inspired by the work of Piet Mondrian. It has been created by using an algorithm that operates on-chain within the Ethereum blockchain.',
        '","attributes":[{"trait_type":"Iterations","value":"',
        mA[0],
        '"},{"trait_type":"Palette","value":"',
        mA[1],
        '"}],"image": "data:image/svg+xml;base64,',
        Base64.encode(bytes(output2)),
        '"}'
        );

        output2 = Base64.encode(bytes(string(abi.encodePacked(output2))));      
        output = string(abi.encodePacked('data:application/json;base64,', output2));        
        return output;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }


    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }
    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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

        _balances[to] += 1;
        _owners[tokenId] = to;

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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
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
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol

pragma solidity ^0.8.0;

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}


pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity >=0.7.0 <0.9.0;

contract OnChainMondrianMotion is ERC721Enumerable, Ownable {
  using Strings for uint256;
  string public baseExtension = ".json";
  uint256 public cost = 0.00 ether;
  uint256 public preSaleCost = 0.00 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmount = 10;
  uint256 public preSaleGroup = 1;
  bool public paused = false;
  bool public refundStatus = true;
  bool public preSale = false;
  address public publicKey = 0xB0F8f33DE6F715aACbFB56D3fe0570EbddcEf776;

    // mapping with dimension for preSaleGroup
    mapping(uint256 => mapping(bytes32 => bool)) public executed;

  constructor(
    string memory _name,
    string memory _symbol
  ) ERC721(_name, _symbol) {
  }
 
    function showText() public view returns (string memory) {
           
    //bytes memory stringContract = abi.encodePacked(address(this));
    uint256 _allocation = 3;
    string memory stringWallet = Strings.toHexString(uint256(uint160(msg.sender)), 20);
    string memory stringAllocation = Strings.toString(_allocation);

    string memory stringContract = Strings.toHexString(uint256(uint160(address(this))), 20);
   
string memory combinedData = string(bytes.concat(bytes(stringWallet), bytes(stringContract), bytes(stringAllocation)));

       return combinedData;
    }


  // public
   function mint(uint256 _mintAmount, bytes memory _sig, uint256 _allocation) public payable {
    uint256 supply = totalSupply();

    // DRM start
  if (preSale == true) {

       cost = preSaleCost;

       string memory stringContract = Strings.toHexString(uint256(uint160(address(this))), 20);
       string memory stringAllocation = Strings.toString(_allocation);
       string memory stringWallet = Strings.toHexString(uint256(uint160(msg.sender)), 20);
       stringContract = toUpper(stringContract);
       stringAllocation = toUpper(stringAllocation);
       stringWallet = toUpper(stringWallet);
       string memory combinedData = string(bytes.concat(bytes(stringWallet), bytes(stringContract), bytes(stringAllocation)));

    bytes32 txHash = getMessageHash(combinedData);
    require(!executed[preSaleGroup][txHash], "Transaction already executed");
    require(verify(publicKey, combinedData, _sig), "Invalid signature");
    require(_mintAmount <= _allocation, "Allocation breached");
    executed[preSaleGroup][txHash] = true;    
    
    }
    // DRM end

    require(!paused, "Contract paused");
    require(_mintAmount > 0, "Mint amount too low");
    require(_mintAmount <= maxMintAmount, "Mint amount too high");
    require(supply + _mintAmount <= maxSupply, "Not enough supply");

    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount, "Price too low");
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);

        // ABOUT THE REFUND
        // ----------------
        // 1 in 3 mints are refunded their mint cost x 2!
        // This is done automatically to the minting wallet address
        // It is important to know that a contract cannot generate a
        // true random number so there is no luck or chance involved.
        // As not to discriminate against people with limited
        // knowledge of coding we will supply a list of all NFT numbers
        // that will trigger a refund. Visit our Discord for the list:
        // https://discord.gg/MeZ6sFWUja
        
        if (refundStatus == true)
        {
        if (cost > 0)
        {
            uint256 random = uint256(keccak256(abi.encodePacked(supply.toString(),i.toString(), "motion"))) %3;
            if (random == 1)
            {
                uint256 refund = (cost / _mintAmount) * 2;
                if (address(this).balance > refund)
                {
                // ok to pay
                    (bool pay, ) = payable(msg.sender).call{value: refund}("");
                    require(pay);
                }
            }
        }
        }

    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }
  
  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function preSaleState(bool _state) public onlyOwner {
    preSale = _state;
  }

  function setPreSaleGroup(uint256 _state) public onlyOwner {
    preSaleGroup = _state;
  }
 
  function setMirgateAddress(string memory _state) public onlyOwner {
    migrateAddress = _state;
  }

  function setMirgate(bool _state) public onlyOwner {
    migrate = _state;
  }

  function refundMode(bool _state) public onlyOwner {
    refundStatus = _state;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

// Signature code
function verify(address _signer, string memory _message, bytes memory _sig) public pure returns (bool)
{
    bytes32 messageHash = getMessageHash(_message);
    bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
    return recover(ethSignedMessageHash, _sig) == _signer;
}
function getMessageHash(string memory _word) internal pure returns(bytes32)
{
    bytes32 output = keccak256(abi.encodePacked(_word));
    return output;
}
function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns(bytes32)
    {
    bytes32 output = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    return output;
    }

function recover(bytes32 _ethSignedMessageHash, bytes memory _sig) internal pure returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = split(_sig);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

function split(bytes memory _sig) internal pure returns (bytes32 r, bytes32 s, uint8 v)
    {
       require(_sig.length == 65, "Invlaid signature length");
       assembly {
           r := mload(add(_sig, 32))
           s := mload(add(_sig, 64))
           v := byte(0, mload(add(_sig, 96)))
       }
    }


function toUpper(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bUpper = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Lowercase character...
            if ((uint8(bStr[i]) >= 97) && (uint8(bStr[i]) <= 122)) {
                // So we subtract 32 to make it uppercase
                bUpper[i] = bytes1(uint8(bStr[i]) - 32);
            } else {
                bUpper[i] = bStr[i];
            }
        }
        return string(bUpper);
    }



}

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
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
}