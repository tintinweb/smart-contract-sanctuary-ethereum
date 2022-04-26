/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
}

interface IERC721Metadata {
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

library MerkleProof {
    
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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

}

library Metadata {
    using Strings for uint256;

    // address public owner;  

    string private constant _name = "lootex mom";
    string private constant _imageBaseURI = "https://astrogator.mypinata.cloud/ipfs/Qmcj1nSiRFcDGQE6QpzNpVZnpJ2sRK7SiYiMSXqkBU33vc/";

    struct ERC721MetadataStructure {
        string name;
        string description;
        string createdBy;
        string image;
        ERC721MetadataAttribute[] attributes;
    }

    struct ERC721MetadataAttribute {
        string traitType;
        string value;
    }

    // constructor () {
    //     owner = msg.sender;
    //     _name = "lootex";
    //     _imageBaseURI = "";
    // }

    function tokenMetadata(uint tokenId, uint colorId) external pure returns (string memory) {
        string memory base64Json = Base64.encode(bytes(string(abi.encodePacked(_getJson(tokenId, colorId)))));
        return string(abi.encodePacked('data:application/json;base64,', base64Json));
    }

    function _getJson(uint tokenId, uint colorId) internal pure returns (string memory) {
        string memory imageData = string(abi.encodePacked(imageBaseURI(), colorId.toString()));

        uint rarity = colorId < 10 ? 1 : colorId < 20 ? 2 : 3;
        uint mergeCount = rarity;

        ERC721MetadataStructure memory metadata = ERC721MetadataStructure({
            name: string(abi.encodePacked(name(), "(", colorId.toString(), ") #", tokenId.toString())),
            description: colorId.toString(),
            createdBy: "Ryan",
            image: imageData,
            attributes: _getJsonAttributes(rarity, mergeCount)
        });

        return _generateERC721Metadata(metadata);
    }

    function _getJsonAttributes(uint256 rarity, uint256 mergeCount) private pure returns (ERC721MetadataAttribute[] memory) {

        ERC721MetadataAttribute[] memory metadataAttributes = new ERC721MetadataAttribute[](2);
        metadataAttributes[0] = _getERC721MetadataAttribute("Tier", rarity.toString());
        metadataAttributes[1] = _getERC721MetadataAttribute("Merges", mergeCount.toString());
        return metadataAttributes;
    }

    function _getERC721MetadataAttribute(string memory traitType, string memory value) private pure returns (ERC721MetadataAttribute memory) {
        ERC721MetadataAttribute memory attribute = ERC721MetadataAttribute({
            traitType: traitType,
            value: value
        });

        return attribute;
    }  

    function _generateERC721Metadata(ERC721MetadataStructure memory metadata) private pure returns (string memory) {
        bytes memory byteString;    
        
        byteString = abi.encodePacked(
            byteString,
            _openJsonObject());
        
        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute("name", metadata.name, true));
        
        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute("description", metadata.description, true));
        
        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute("created_by", metadata.createdBy, true));
        
        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute("image_data", metadata.image, true));

        byteString = abi.encodePacked(
            byteString,
            _pushJsonComplexAttribute("attributes", _getAttributes(metadata.attributes), false));
        
        byteString = abi.encodePacked(
            byteString,
            _closeJsonObject());
    
        return string(byteString);
    }

    function _getAttributes(ERC721MetadataAttribute[] memory attributes) private pure returns (string memory) {
        bytes memory byteString;
    
        byteString = abi.encodePacked(
            byteString,
            _openJsonArray());
    
        for (uint i = 0; i < attributes.length; i++) {
            ERC721MetadataAttribute memory attribute = attributes[i];

            byteString = abi.encodePacked(
                byteString,
                _pushJsonArrayElement(_getAttribute(attribute), i < (attributes.length - 1)));
        }
    
        byteString = abi.encodePacked(
            byteString,
            _closeJsonArray());
    
        return string(byteString);
    }

    function _getAttribute(ERC721MetadataAttribute memory attribute) private pure returns (string memory) {
        bytes memory byteString;
        
        byteString = abi.encodePacked(
            byteString,
            _openJsonObject());

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute("trait_type", attribute.traitType, true));
    
        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveNonStringAttribute("value", attribute.value, false));

        byteString = abi.encodePacked(
            byteString,
            _closeJsonObject());
    
        return string(byteString);
    }

    function _pushJsonPrimitiveStringAttribute(string memory key, string memory value, bool insertComma) private pure returns (string memory) {
        return string(abi.encodePacked('"', key, '": "', value, '"', insertComma ? ',' : ''));
    }

    function _pushJsonPrimitiveNonStringAttribute(string memory key, string memory value, bool insertComma) private pure returns (string memory) {
        return string(abi.encodePacked('"', key, '": ', value, insertComma ? ',' : ''));
    }

    function _pushJsonComplexAttribute(string memory key, string memory value, bool insertComma) private pure returns (string memory) {
        return string(abi.encodePacked('"', key, '": ', value, insertComma ? ',' : ''));
    }

    function _pushJsonArrayElement(string memory value, bool insertComma) private pure returns (string memory) {
        return string(abi.encodePacked(value, insertComma ? ',' : ''));
    }

    function _openJsonObject() private pure returns (string memory) {        
        return string(abi.encodePacked("{"));
    }

    function _closeJsonObject() private pure returns (string memory) {
        return string(abi.encodePacked("}"));
    }

    function _openJsonArray() private pure returns (string memory) {        
        return string(abi.encodePacked("["));
    }

    function _closeJsonArray() private pure returns (string memory) {        
        return string(abi.encodePacked("]"));
    }

    // function _requireOnlyOwner() private view {
    //     require(msg.sender == owner, "You are not the owner");
    // }

    // function setName(string calldata name_) external { 
    //     _requireOnlyOwner();       
    //     _name = name_;
    // }

    // function setImageBaseURI(string calldata imageBaseURI_) external {        
    //     _requireOnlyOwner();
    //     _imageBaseURI = imageBaseURI_;
    // }

    function imageBaseURI() public pure returns (string memory) {
        return _imageBaseURI;
    }

    function name() public pure returns (string memory) {
        return _name;
    }
}

contract Mother is IERC721, IERC721Metadata {
    uint public seed; // 用戶Unpack 時 依照seed  & unpack 公式決定可領到什麼獎品

    string private _name;
    string private _symbol;
    string private _unpackImg;

    // Mapping token ID to color value.
    mapping (uint => uint) private _colors;

    // Mapping from token ID to owner address.
    mapping (uint => address) private _owners;

    // Mapping from token ID to approved address.
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals.
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    mapping (address => uint) private whitelistPurchased;

    // Mapping owner address to their tokens
    mapping(address => uint[]) _holderTokens;

    // Mapping owner address to their token's index
    mapping (address => mapping (uint => uint)) _indexes;

    uint private constant rPoint = 5;
    uint private constant gPoint = 7;
    uint private constant bPoint = 9;
    uint private constant rgbPoint = 21;
    uint public constant price = 0.01e18; // 10 MATIC
    uint public constant maxPurchase = 10;

    uint public nextTokenId;

    address public treasury;
    address private _owner;

    bytes32 public root = 0x976274cb4d4f66f60c0e93e8b602f00aa6fdcfbde9c0b498db51bf0ab8af70de;

    constructor () {
        treasury = _msgSender();
        _owner = _msgSender();
        _name = "mother";
        _symbol = "MM";
    }
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function mint(uint amount) external payable {
        require(price * amount == msg.value, "Ether value sent incorrect");
        require(amount <= maxPurchase, "10 tokens once");

        uint _nextTokenId = nextTokenId;
        address operator = _msgSender();
        payable(treasury).transfer(msg.value);
        for (uint i = 0; i < amount; ++i) {
            uint tokenIdToBeMint = _nextTokenId + i;
            _holderTokens[operator].push(tokenIdToBeMint);
            _indexes[operator][tokenIdToBeMint] = _holderTokens[operator].length - 1;
            _owners[tokenIdToBeMint] = operator;
            emit Transfer(address(0), operator, tokenIdToBeMint);
        }
        nextTokenId += amount;
    }

    function mintForFree(uint amount) external {
        address operator = _msgSender();
        require(amount <= maxPurchase, "10 tokens once");
        require(whitelistPurchased[operator] + amount <= maxPurchase, "Free mint maximum: 10");
        // require(MerkleProof.verify(proof, root, keccak256(abi.encodePacked(operator))), "Not whitelisted");

        uint _nextTokenId = nextTokenId;
        // treasury.transfer(msg.value);
        for (uint i = 0; i < amount; ++i) {
            uint tokenIdToBeMint = _nextTokenId + i;
            _holderTokens[operator].push(tokenIdToBeMint);
            _owners[tokenIdToBeMint] = operator;
            _indexes[operator][tokenIdToBeMint] = _holderTokens[operator].length - 1;
            emit Transfer(address(0), operator, tokenIdToBeMint);
        }
        whitelistPurchased[operator] += amount;
        nextTokenId += amount;
    }

    // toFix: 已unpack本來是b，有可能變成rg => 不可能？
    // 本來tokenId是r，因為被洗牌，最後變成g => ？
    function unpack() external {
        address operator = _msgSender();
        uint balance = balanceOf(operator);
        require(balance > 0, "Where's your NFT");

        // if need to process merge
        if(balance > 1) {
            uint[] memory _ids = _holderTokens[operator];
            uint[] memory _cs; // colors array

            uint alreadyUnpacked;
            uint rAmount;
            uint gAmount;
            uint bAmount;

            /*
             * 如果已經有unpacked token && != r,g,b，放進alreadyUnpacked
             * otherwise，加入個別rgb的amount
            */
            for (uint i = 0; i < balance; ++i) {
                uint _tokenId = _ids[i];
                if (_colors[_tokenId] > 10) {
                    ++alreadyUnpacked;
                } else {
                    uint color = getColor(_tokenId);
                    if (color == rPoint) {
                        ++rAmount;
                    }
                    else if (color == gPoint) {
                        ++gAmount;
                    }
                    else {
                        ++bAmount;
                    }
                }
            }

            // 處理 already unpacked
            for (uint y = 0; y < alreadyUnpacked; ++y) {
                uint _rgbPoint = rgbPoint;
                uint _tokenId = _ids[y];
                uint color = _colors[_tokenId];
                if (color == _rgbPoint) continue;

                uint needColor = _rgbPoint - color;
                if (needColor == rPoint && rAmount != 0) {
                    --rAmount;
                    _colors[_tokenId] = _rgbPoint;
                    continue;
                }
                if (needColor == gPoint && gAmount != 0) {
                    --gAmount;
                    _colors[_tokenId] = _rgbPoint;
                    continue;
                }
                if (needColor == bPoint && bAmount != 0) {
                    --bAmount;
                    _colors[_tokenId] = _rgbPoint;
                    continue;
                }
            }

            uint largest = getLargest(rAmount, gAmount, bAmount);
            _cs = new uint[](largest);

            // 留下的tokenId只會是最多個的顏色
            // [1,2,6,7,8,9] => [r,r,r,g,g,b] 不用管tokenId對應的顏色，我只要知道有哪些顏色，然後從index後面的開始burn

            // 處理merge
            for (uint j = 0; j < largest; ++j) {
                uint color;
                if (rAmount != 0) {
                    --rAmount;
                    color += rPoint;
                }
                if (gAmount != 0) {
                    --gAmount;
                    color += gPoint;
                }
                if (bAmount != 0) {
                    --bAmount;
                    color += bPoint;
                }
                _cs[j] = color;
            }

            // give color
            for (uint x = alreadyUnpacked; x < largest + alreadyUnpacked; ++x) {
                _colors[_ids[x]] = _cs[x - alreadyUnpacked];
            }

            // burn
            for (uint k = largest + alreadyUnpacked; k < balance; ++k) {
                _burnLast(_ids[k]);
            }

        } else {
            uint _tokenId = _holderTokens[operator][0];
            _colors[_tokenId] = getColor(_tokenId);
        }
    }

    function getLargest(uint _f, uint _s, uint _t) internal pure returns (uint largest) {
        largest = _f >= _s ? _f : _s;
        if (largest < _t) largest = _t;
    }

    // todo: getColor公式，有機率合成黃金花
    function getColor(uint tokenId) internal view returns (uint) {
        if (_colors[tokenId] > 0 ) return _colors[tokenId];
        if (tokenId == 0 || tokenId % 3 == 1) return 5;
        else if (tokenId % 3 == 2) return 7;
        else return 9; 
        // 某種公式取得該tokenId顏色
    }

    function colorOf(uint tokenId) external view returns(uint) {
        return _colors[tokenId];
    }

    function _transfer(address from, address to, uint tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        uint balance = balanceOf(to);
        if(balance > 0) {
            uint _rgbPoint = rgbPoint;
            uint[] memory _ids = _holderTokens[to];
            for (uint i = 0; i < balance; ++i) {
                if (_ids[i] == _rgbPoint) continue; // rgb
                uint colorFrom = _colors[tokenId];
                uint colorTo = _colors[_ids[i]];

                if (colorTo == colorFrom) break; // to be validate
                // if (colorTo == colorFrom && colorFrom < 10) break;
                // if (colorTo == colorFrom || _rgbPoint - colorTo != colorFrom) continue;
                if (_rgbPoint - colorTo != colorFrom) continue;

                _colors[_ids[i]] = colorTo + colorFrom;
                _approve(address(0), tokenId);
                delete _colors[tokenId];
                delete _owners[tokenId];

                break;
            }
        }


        // removing token from "from"
        uint toDeleteIndex = _indexes[from][tokenId];
        uint lastIndex = _holderTokens[from].length - 1;
        uint lastValue = _holderTokens[from][lastIndex];
        _holderTokens[from][toDeleteIndex] = lastValue;
        _indexes[from][lastValue] = toDeleteIndex;
        _holderTokens[from].pop();
        delete _indexes[from][tokenId];

        if (_owners[tokenId] != address(0)) {
            // if not merged, transfer to "to"
            _approve(address(0), tokenId);
            _holderTokens[to].push(tokenId);
            _indexes[to][tokenId] = _holderTokens[to].length - 1;
            _owners[tokenId] = to;
        }

        emit Transfer(from, to, tokenId);
    }

    function _merge(uint tokenIdRcvr, uint tokenIdSndr) internal {
        //
    }

    function tokenOfOwnerByIndex(address owner, uint index) external view returns (uint) {
        return _holderTokens[owner][index];
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "NFT: burn caller is not owner nor approved");
        _burn(tokenId);
    }

    function _burn(uint tokenId) internal {
        // Clear approvals
        _approve(address(0), tokenId);

        address owner = ownerOf(tokenId);
        uint toDeleteIndex = _indexes[owner][tokenId];
        uint lastIndex = _holderTokens[owner].length - 1;
        uint lastValue = _holderTokens[owner][lastIndex];
        _holderTokens[owner][toDeleteIndex] = lastValue;
        _indexes[owner][lastValue] = toDeleteIndex;
        _holderTokens[owner].pop();
        delete _indexes[owner][tokenId];
        delete _owners[tokenId];
        delete _colors[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _burnLast(uint tokenId) internal {
        // Clear approvals
        _approve(address(0), tokenId);

        address owner = _msgSender();
        _holderTokens[owner].pop();
        delete _indexes[owner][tokenId];
        delete _owners[tokenId];
        delete _colors[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function balanceOf(address operator) public view override returns (uint) {
        return _holderTokens[operator].length;
    }

    function ownerOf(uint256 tokenId) public view override returns (address owner) {
        owner = _owners[tokenId];
        require(owner != address(0), "ERC721: nonexistent token");
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        emit Approval(ownerOf(tokenId), to, tokenId);
        _tokenApprovals[tokenId] = to;
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: nonexistent token");       
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setUnpackImg(string memory unpackImg_) external onlyOwner {
        _unpackImg = unpackImg_;
    }

    function name() external view virtual override returns (string memory){
        return _name;
    }

    function symbol() external view virtual override returns (string memory){
        return _symbol;
    }


    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        // 根據tokenId, color
        require(_exists(tokenId), "ERC721: nonexistent token");

        if (_colors[tokenId] == 0) return _unpackImg;

        return Metadata.tokenMetadata(
            tokenId,
            _colors[tokenId]
        );
    }
    function totalSupply() public view returns (uint256) {
        return nextTokenId;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                }
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
        return true;
    }    

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        bytes4 _ERC165_ = 0x01ffc9a7;
        bytes4 _ERC721_ = 0x80ac58cd;
        bytes4 _ERC2981_ = 0x2a55205a;
        bytes4 _ERC721Metadata_ = 0x5b5e139f;
        return interfaceId == _ERC165_ 
            || interfaceId == _ERC721_
            || interfaceId == _ERC2981_
            || interfaceId == _ERC721Metadata_;
    }

    // function withdraw() external onlyOwner {
    //     payable(treasury).call{value:address(this).balance}("");
    // }
}