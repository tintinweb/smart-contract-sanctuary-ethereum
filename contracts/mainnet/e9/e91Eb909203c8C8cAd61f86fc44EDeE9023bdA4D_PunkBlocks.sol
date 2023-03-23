/**
 *Submitted for verification at Etherscan.io on 2023-03-23
*/

// SPDX-License-Identifier: MIT
// Author: tycoon.eth, thanks to @geraldb & @samwilsn on Github for inspiration!
// Version: v0.1.3
// Note: The MIT license is for the source code only. Images registered through
// this contract retain all of their owner's rights. This contract
// is a non-profit "library" project and intended to archive & preserve punk
// images, so that they can become widely accessible for decentralized
// applications, including marketplaces, wallets, galleries, etc.
pragma solidity ^0.8.19;
/**

 ███████████                        █████
░░███░░░░░███                      ░░███
 ░███    ░███ █████ ████ ████████   ░███ █████
 ░██████████ ░░███ ░███ ░░███░░███  ░███░░███
 ░███░░░░░░   ░███ ░███  ░███ ░███  ░██████░
 ░███         ░███ ░███  ░███ ░███  ░███░░███
 █████        ░░████████ ████ █████ ████ █████
░░░░░          ░░░░░░░░ ░░░░ ░░░░░ ░░░░ ░░░░░



 ███████████  ████                    █████
░░███░░░░░███░░███                   ░░███
 ░███    ░███ ░███   ██████   ██████  ░███ █████  █████
 ░██████████  ░███  ███░░███ ███░░███ ░███░░███  ███░░
 ░███░░░░░███ ░███ ░███ ░███░███ ░░░  ░██████░  ░░█████
 ░███    ░███ ░███ ░███ ░███░███  ███ ░███░░███  ░░░░███
 ███████████  █████░░██████ ░░██████  ████ █████ ██████
░░░░░░░░░░░  ░░░░░  ░░░░░░   ░░░░░░  ░░░░ ░░░░░ ░░░░░░

            A Registry of 24x24 png images

This contract:

1. Stores all the classic traits of the CryptoPunks in
individual png files, 100% on-chain. These are then used as
blocks to construct CryptoPunk images. Outputted as SVGs.

2. Any of the 10,000 "classic" CryptoPunks can be generated
by supplying desired arguments to a function, such as
the id of a punk, or a list of the traits.

3. An unlimited number of new punk images can be generated from
the existing classic set of traits, or even from new traits!

4. New traits (blocks) can be added to the contract by
registering them with the `registerBlock` function.

Further documentation:
https://github.com/0xTycoon/punk-blocks

*/

//import "hardhat/console.sol";

contract PunkBlocks {
    using DynamicBufferLib for DynamicBufferLib.DynamicBuffer;
    address admin;
    // Layer is in the order of rendering
    enum Layer {
        Base,      //0 Base is the face. Determines if m or f version will be used to render the remaining layers
        Mouth,     //1 (Hot Lipstick, Smile, Buck Teeth, ...)
        Cheeks,    //2 (Rosy Cheeks)
        Blemish,   //3 (Mole, Spots)
        Eyes,      //4 (Clown Eyes Green, Green Eye Shadow, ...)
        Neck,      //5 (Choker, Silver Chain, Gold Chain)
        Beard,     //6 (Big Beard, Front Beard, Goat, ...)
        Ears,      //7 (Earring)
        HeadTop1,  //8 (Purple Hair, Shaved Head, Beanie, Fedora,Hoodie)
        HeadTop2,  //9 eg. sometimes an additional hat over hair
        Eyewear,   //10 (VR, 3D Glass, Eye Mask, Regular Shades, Welding Glasses, ...)
        MouthProp, //11 (Medical Mask, Cigarette, ...)
        Nose       //12 (Clown Nose)
    }
    struct Block {
        Layer layer; // 13 possible layers
        bytes blockL;// male version of this attribute
        bytes blockS;// female version of this attribute
    }
    mapping(bytes32 => bytes) public blockS;      // small attributes as png
    mapping(bytes32 => bytes) public blockL;      // large attributes as png
    mapping(bytes32 => uint256) public blocksInfo;// byte 0: layer, byte 1-2: blockL.length, byte 3-5: blockS.length
    mapping (uint32 => mapping(Layer => uint16)) public orderConfig; // layer => seq
    uint32 public nextConfigId;
    uint32 public nextId;                    // next id to use when adding a block
    mapping(uint32 => bytes32) public index; // index of each block by its sequence
    mapping(uint256 => Layer) public blockToLayer;
    event NewBlock(address, uint32, string);

    uint256 constant private bit1byte  =  0xFF;         // bit mask 1
    uint256 constant private bit2byte  =  0xFFFF00;     // bit mask 2
    uint256 constant private bit3byte  =  0xFFFF000000; // bit mask 3

    /**
    * @dev getBlocks returns a sequential list of blocks in a single call
    * @param _fromID is which id to begin from
    * @param _count how many items to retrieve.
    * @return Block[] list of blocks, uint256 next id
    */
    function getBlocks(
        uint _fromID,
        uint _count) external view returns(Block[] memory, uint32) {
        Block[] memory ret = new Block[](_count);
        while (_count != 0) {
            bytes32 i = index[uint32(_fromID + _count - 1)];
            uint256 info = blocksInfo[i];
            if (info > 0) {
                (Layer l,,) = _unpackInfo(info);
                ret[_count-1].blockS = blockS[i];
                ret[_count-1].blockL = blockL[i];
                ret[_count-1].layer = l;
            }
            _count--;
        }
        return (ret, nextId);
    }

    /**
    * registerOrderConfig
    */
    function registerOrderConfig(
        Layer[] calldata _order
    ) external {
        mapping(Layer => uint16) storage c = orderConfig[nextConfigId];
        for (uint16 i = 0; i < _order.length; i++) {
            require(c[Layer(i)] == 0, "storage must be empty");
            c[Layer(i)] = uint16(i);
        }
        nextConfigId++;
    }

    function _packInfo(uint8 _layer, uint16 _l, uint16 _s) pure internal returns (uint256) {
        uint256 scratch;
        scratch = uint256(_layer);
        scratch = (uint256(_l) << 8) | scratch; // 16 bit uint, m length
        scratch = (uint256(_s) << 24) | scratch;// 16 bit uint, f length
        return scratch;
    }

    /**
    * _unpackInfo extracts block information
    */
    function _unpackInfo(uint256 _info) pure internal returns(Layer, uint16, uint16) {
        Layer layer = Layer(uint8(_info));
        uint16 l = uint16((_info & bit2byte) >> 8);
        uint16 s = uint16((_info & bit3byte) >> 24);
        return (layer, l, s);
    }

    /**
    * get info about a block
    */
    function info(bytes32 _id) view public returns(Layer, uint16, uint16) {
        uint256 info = blocksInfo[_id];
        if (info == 0) {
            return (Layer.Base, 0, 0);
        }
        return _unpackInfo(info);
    }

    /**
    * @dev registerBlock allows anybody to add a new block to the contract.
    *   Either _dataL or _dataF, or both, must contain a byte stream of a png file.
    *   It's best if the png is using an 'index palette' and the lowest bit depth possible,
    *   while keeping the highest compression setting.
    * @param _dataL png data for the larger male version, 24x24
    * @param _dataS png data for the smaller female version, 24x24
    * @param _layer 0 to 12, corresponding to the Layer enum type.
    * @param _name the name of the trait, Camel Case. e.g. "Luxurious Beard"
    */
    function registerBlock(
        bytes calldata _dataL,
        bytes calldata _dataS,
        uint8 _layer,
        string memory _name) external
    {
        bytes32 key = keccak256(abi.encodePacked(_name));
        uint256 info = blocksInfo[key];
        require (info == 0, "slot taken");
        require (_layer < 13, "invalid _layer");
        require (_dataL.length + _dataS.length > 0, "no data");
        require (_dataL.length <= type(uint16).max, "L too big");
        require (_dataS.length <= type(uint16).max, "S too big");
        if (_layer==0 && _dataL.length > 0 && _dataS.length > 0) {
            revert("layer0 cannot have both versions");
        }
        if (_dataL.length > 0) {
            require (_validatePng(_dataL), "invalid L png");
            blockL[key] = _dataL;
        }
        if (_dataS.length > 0) {
            require (_validatePng(_dataS), "invalid S png");
            blockS[key] = _dataS;
        }
        blocksInfo[key] = _packInfo(_layer, uint16(_dataL.length), uint16(_dataS.length));
        index[nextId] = key;
        unchecked{nextId++;}
        emit NewBlock(msg.sender, nextId, _name);
    }

    /**
    * @dev Just a limited png validation. Only verifies that the png is 24x24 and has a png structure,
    *   but doesn't validate any checksums or any other validation
    */
    function _validatePng(bytes calldata _data) pure internal returns (bool) {
    unchecked {
        if (_data.length < 8) {
            return false;
        }
        bytes memory pngHeader = bytes("\x89PNG\r\n\x1a\n"); // first 8 bytes
        uint pos;
        while (pos < 8) {
            if (_data[pos] != pngHeader[pos]) {
                return false;
            }
            pos++;
        }
        int32 chunkLen;
        while (true) {
            // next 4 bytes represent a big-endian int32, the chunk length
            chunkLen = int32(uint32(uint8(_data[pos+3]))
            | uint32(uint8(_data[pos+2]))<<8
            | uint32(uint8(_data[pos+1]))<<16
                | uint32(uint8(_data[pos]))<<24);
            pos += 4;
            if (
                _data[pos] == bytes1("I") &&
                _data[pos+1] == bytes1("H") &&
                _data[pos+2] == bytes1("D") &&
                _data[pos+3] == bytes1("R")) { // IHDR
                if (24 != int32(uint32(uint8(_data[pos+7]))
                | uint32(uint8(_data[pos+6]))<<8
                | uint32(uint8(_data[pos+5]))<<16
                    | uint32(uint8(_data[pos+4]))<<24)) { // width needs to be 24
                    return false;
                }
                if (24 != int32(uint32(uint8(_data[pos+11]))
                | uint32(uint8(_data[pos+10]))<<8
                | uint32(uint8(_data[pos+9]))<<16
                    | uint32(uint8(_data[pos+8]))<<24)) { // height needs to be 24
                    return false;
                }
            } else if (
                _data[pos] == bytes1("P") &&
                _data[pos+1] == bytes1("L") &&
                _data[pos+2] == bytes1("T") &&
                _data[pos+3] == bytes1("E")) {  // PLTE
            } else if (
                _data[pos] == bytes1("t") &&
                _data[pos+1] == bytes1("R") &&
                _data[pos+2] == bytes1("N") &&
                _data[pos+3] == bytes1("S")) {  // tRNS
            } else if (
                _data[pos] == bytes1("I") &&
                _data[pos+1] == bytes1("D") &&
                _data[pos+2] == bytes1("A") &&
                _data[pos+3] == bytes1("T")) {  // IDAT
            } else if (
                _data[pos] == bytes1("I") &&
                _data[pos+1] == bytes1("E") &&
                _data[pos+2] == bytes1("N") &&
                _data[pos+3] == bytes1("D")) {  // IEND
                return true;                    // png is valid (without checking the CRC)
            } else {
                return false;
            }
            pos += 4 + uint(int(chunkLen)) + 4; // skip the payload, ignore CRC
        }
    } //unchecked
        return true;
    }

    /**
    * @dev svgFromNames returns the svg data as a string
    * @param _attributeNames a list of attribute names, eg "Male 1", "Goat"
    *   must have at least 1 layer 0 attribute (eg. Male, Female, Alien, Ape, Zombie)
    *   e.g. ["Male 1","Goat"]
    *   Where "Male 1" is a layer 0 attribute, that decides what version of
    *   image to use for the higher
    *   layers (dataMale or dataFemale)
    * @param _size the width and height of generated svg, eg. 24
    * @param _orderID which order config to use when rendering, 0 is the default
    */
    function svgFromNames(
        string[] memory _attributeNames,
        uint16 _x,
        uint16 _y,
        uint16 _size,
        uint32 _orderID) external view returns (string memory){
        bool isLarge;
        bytes32[] memory layerKeys = new bytes32[](13);
        for (uint16 i = 0; i < _attributeNames.length; i++) {
            bytes32 hash = keccak256(
                abi.encodePacked(_attributeNames[i]));
            uint256 fo = blocksInfo[hash];
            if (fo == 0) {
                break;
            }
            (Layer l, uint16 sL,) = _unpackInfo(fo);
            layerKeys[uint256(orderConfig[_orderID][l])] = hash;
            if (l == Layer.Base) {
                // base later
                if (sL > 0) {
                    isLarge = true;
                }
            }
        }
        return _svg(layerKeys, _x, _y, _size, isLarge);
    }

    /**
    * @dev svgFromKeys returns the svg data as a string
    * @param _attributeKeys a list of attribute names that have been hashed,
    *    eg keccak256("Male 1"), keccak256("Goat")
    *    must have at least 1 layer 0 attribute (eg. keccak256("Male 1")) which
    *    decides what version of image to use for the higher layers
    *    (dataMale or dataFemale)
    *    e.g. ["0x9039da071f773e85254cbd0f99efa70230c4c11d63fce84323db9eca8e8ef283",
    *    "0xd5de5c20969a9e22f93842ca4d65bac0c0387225cee45a944a14f03f9221fd4a"]
    * @param _size the width and height of generated svg, eg. 24
    * @param _orderID which order config to use when rendering, 0 is the default
    */
    function svgFromKeys(
        bytes32[] memory _attributeKeys,
        uint16 _x,
        uint16 _y,
        uint16 _size,
        uint32 _orderID) external view returns (string memory) {
        bool isLarge;
        bytes32[] memory layerKeys = new bytes32[](13);
        for (uint16 i = 0; i < _attributeKeys.length; i++) {
            uint256 fo = blocksInfo[_attributeKeys[i]];
            if (fo == 0) {
                break;
            }
            (Layer l, uint16 sL,) = _unpackInfo(fo);
            layerKeys[uint256(orderConfig[_orderID][l])] = _attributeKeys[i];
            if (l == Layer.Base) {
                // base later
                if (sL > 0) {
                    isLarge = true;
                }
            }
        }
        return _svg(layerKeys, _x, _y, _size, isLarge);
    }

    /**
    * @dev svgFromIDs returns the svg data as a string
    *   e.g. [9,55,99]
    *   One of the elements must be must be a layer 0 block.
    *   This element decides what version of image to use for the higher layers
    *   (dataMale or dataFemale)
    * @param _ids uint256 ids of an attribute, by it's index of creation
    * @param _size the width and height of generated svg, eg. 24
    * @param _orderID which order config to use when rendering, 0 is the default
    */
    function svgFromIDs(
        uint32[] calldata _ids,
        uint16 _x,
        uint16 _y,
        uint16 _size,
        uint32 _orderID) external view returns (string memory) {
        bool isLarge;
        bytes32[] memory layerKeys = new bytes32[](13);
        for (uint16 i = 0; i < _ids.length; i++) {
            bytes32 hash = index[_ids[i]];
            uint256 fo = blocksInfo[hash];
            if (fo == 0) {
                break;
            }
            (Layer l, uint16 sL,) = _unpackInfo(fo);
            layerKeys[uint256(orderConfig[_orderID][l])] = hash;
            if (l == Layer.Base) {
                // base later
                if (sL > 0) {
                    isLarge = true;
                }
            }
        }
        return _svg(layerKeys, _x, _y, _size, isLarge);
    }

    /**
    * @dev svgFromPunkID returns the svg data as a string given a punk id
    * @param _tokenID uint256 IDs a punk id, 0-9999
    * @param _size the width and height of generated svg, eg. 24
    * @param _orderID which order config to use when rendering, 0 is the default
    */
    function svgFromPunkID(
        uint256 _tokenID,
        uint16 _x,
        uint16 _y,
        uint16 _size,
        uint32 _orderID
    ) external view returns (string memory) {
        // Get the attributes first, using https://github.com/0xTycoon/punks-token-uri
        IAttrParser p = IAttrParser(0xD8E916C3016bE144eb2907778cf972C4b01645fC);
        string[8] memory _attributeNames = p.parseAttributes(_tokenID);
        bool isLarge;
        bytes32[] memory layerKeys = new bytes32[](13);
        for (uint16 i = 0; i < 8; i++) {
            if (bytes(_attributeNames[i]).length == 0) {
                break;
            }
            bytes32 hash = keccak256(
                abi.encodePacked(_attributeNames[i]));
            uint256 fo = blocksInfo[hash];
            if (fo == 0) {
                break;
            }
            (Layer l, uint16 sL,) = _unpackInfo(fo);
            layerKeys[uint256(orderConfig[_orderID][l])] = hash;
            if (l == Layer.Base) {
                // base later
                if (sL > 0) {
                    isLarge = true;
                }
            }
        }
        return _svg(layerKeys, _x, _y, _size, isLarge);
    }


    bytes constant header1 = '<svg class="punkblock" width="';
    bytes constant header2 = '" height="';
    bytes constant header3 = '" x="';
    bytes constant header4 = '" y="';
    bytes constant header5 = '" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" > <style> .pix {image-rendering:pixelated;-ms-interpolation-mode: nearest-neighbor;image-rendering: -moz-crisp-edges;} </style>';
    bytes constant end = '</svg>';
    bytes constant imgStart = '<foreignObject x="0" y="0" width="24" height="24"> <img xmlns="http://www.w3.org/1999/xhtml"  width="100%" class="pix" src="data:image/png;base64,';
    bytes constant imgEnd = '"/></foreignObject>';
    /**
    * @dev _svg build the svg, layer by layer.
    * @return string of the svg image
    */
    function _svg(
        bytes32[] memory _keys,
        uint16 _x,
        uint16 _y,
        uint16 _size,
        bool isLarge
    ) internal view returns (string memory) {
        bytes memory s = bytes(toString(_size));
        DynamicBufferLib.DynamicBuffer memory result;
        result.append(header1, s, header2);
        result.append(s, header3, bytes(toString(_x)));
        result.append(header4, bytes(toString(_y)), header5);
        for (uint256 i = 0; i < 13; i++) {
            if (_keys[i] == 0x0) {
                continue;
            }
            (, uint16 s1, uint16 s2) = info(_keys[i]);
            if (isLarge) {
                if (s1 == 0) {
                    continue; // no data
                }
                result.append(imgStart, bytes(Base64.encode(blockL[_keys[i]])), imgEnd);
            } else {
                if (s2 == 0) {
                    continue; // no data
                }
                result.append(imgStart, bytes(Base64.encode(blockS[_keys[i]])), imgEnd);
            }
        }
        result.append(end);
        return string(result.data);
    }

    /**
    * Here we initialize `blocks` storage with the entire set of original CryptoPunk attributes
    */
    constructor() {
        // Initial blocks that were sourced from https://github.com/cryptopunksnotdead/punks.js/blob/master/yeoldepunks/yeoldepunks-24x24.png

        bytes32 hash;

        hash = hex"9039da071f773e85254cbd0f99efa70230c4c11d63fce84323db9eca8e8ef283";
        blocksInfo[hash] = 45824;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180403000000125920cb00000012504c5445000000000000713f1d8b532c5626007237092b4acd040000000174524e530040e6d8660000004f4944415478da62a00a1014141480b11995949414611c2165252525989490113247092747c549c945006698629092a800c264b8324674030489315a49118f3284ab9590fc23045783cc01040000ffffd8690b6ca3604b190000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"dfcbad4edd134a08c17026fc7af40e146af242a3412600cee7c0719d0ac42d53";
        blocksInfo[hash] = 45824;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180403000000125920cb00000012504c5445000000000000ae8b61b69f8286581ea77c470e17bdef0000000174524e530040e6d8660000004f4944415478da62a00a1014141480b11995949414611c2165252525989490113247092747c549c945006698629092a800c264b8324674030489315a49118f3284ab9590fc23045783cc01040000ffffd8690b6ca3604b190000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"ed94d667f893279240c415151388f335b32027819fa6a4661afaacce342f4c54";
        blocksInfo[hash] = 45824;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180403000000125920cb00000012504c5445000000000000dbb180e7cba9a66e2cd29d601a5e5ef40000000174524e530040e6d8660000004f4944415478da62a00a1014141480b11995949414611c2165252525989490113247092747c549c945006698629092a800c264b8324674030489315a49118f3284ab9590fc23045783cc01040000ffffd8690b6ca3604b190000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"1323f587f8837b162082b8d221e381c5e015d390305ce6be8ade3ff70e70446e";
        blocksInfo[hash] = 45824;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180403000000125920cb00000012504c5445000000000000ead9d9ffffffa58d8dc9b2b21adbe9c60000000174524e530040e6d8660000004f4944415478da62a00a1014141480b11995949414611c2165252525989490113247092747c549c945006698629092a800c264b8324674030489315a49118f3284ab9590fc23045783cc01040000ffffd8690b6ca3604b190000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"1bb61a688fea4953cb586baa1eadb220020829a1e284be38d2ea8fb996dd7286";
        blocksInfo[hash] = 3003121664;
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180403000000125920cb00000015504c5445000000000000713f1d8b532c5626007237094a120162eb383b0000000174524e530040e6d8660000004c4944415478da62a03160141414807384949414e112ca4a4a4a302946255c1c2115272517384731484914c61154c26380102e19b5343807c5390c42082d208b0419905c2d80c901040000ffff2f3c090f8ffce8ac0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"47cc6a8e17679da04a479e5d29625d737670c27b21f8ccfb334e6af61bf6885a";
        blocksInfo[hash] = 3003121664;
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180403000000125920cb00000015504c5445000000000000ae8b61b69f8286581ea77c475f1d096e17a6860000000174524e530040e6d8660000004c4944415478da62a03160141414807384949414e112ca4a4a4a302946255c1c2115272517384731484914c61154c26380102e19b5343807c5390c42082d208b0419905c2d80c901040000ffff2f3c090f8ffce8ac0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"80547b534287b04dc7e9afb751db65a7515fde92b8c2394ae341e3ae0955d519";
        blocksInfo[hash] = 3003121664;
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180403000000125920cb00000015504c5445000000000000dbb180e7cba9a66e2cd29d60711010e7210e7f0000000174524e530040e6d8660000004c4944415478da62a03160141414807384949414e112ca4a4a4a302946255c1c2115272517384731484914c61154c26380102e19b5343807c5390c42082d208b0419905c2d80c901040000ffff2f3c090f8ffce8ac0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"c0c9e42e9d271c94b57d055fc963197e4c62d5933e371a7449ef5d59f26be00a";
        blocksInfo[hash] = 3003121664;
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180403000000125920cb00000015504c5445000000000000ead9d9ffffffa58d8dc9b2b2711010f69870510000000174524e530040e6d8660000004c4944415478da62a03160141414807384949414e112ca4a4a4a302946255c1c2115272517384731484914c61154c26380102e19b5343807c5390c42082d208b0419905c2d80c901040000ffff2f3c090f8ffce8ac0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"f41cb73ce9ba5c1f594bcdfd56e2d14e42d2ecc23f0a4863835bdd4baacd8b72";
        blocksInfo[hash] = 46848;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180403000000125920cb00000012504c54450000000000007da2699bbc885e7253ff00007efb409c0000000174524e530040e6d866000000534944415478da62a00a1014141480b11995949414611c2165252525989490113247092747c549c945006698aa9052209ca3a2a4e404e3a01b20488cd14a8ac8ca545095215cad84e41f21b81a640e200000ffffea5f0b90848c25f90000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"b1ea1507d58429e4dfa3f444cd2e584ba8909c931969bbfb5f1e21e2ac8b758d";
        blocksInfo[hash] = 50176;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180403000000125920cb00000012504c5445000000000000352410856f566a563fa98c6b35cdf9490000000174524e530040e6d866000000604944415478daaccfd11180200c0350d980c0390071821a37d00ddc7f17bf68eb9d9ff2c5bb062e5d7e3900eabc179263a29164fdc4009a43921cc7a9abcecfecd6ea48b1f27eb3990528ed31c9b10ef4409e0cc9a275daa779e58c270000ffff866f0d065247e95a0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"62223f0b03d25507f52a69efbbdbcfdc7579756a7a08a95a2f0e72ada31e32b8";
        blocksInfo[hash] = 47616;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180403000000125920cb00000012504c5445000000000000c8fbfb9be0e0f1ffff75bdbd4053c1210000000174524e530040e6d866000000564944415478daac8fb11180300c03c906b198207fb040466003f65f86061335ee70e53feb6469fb6522a2e7de8091a003c8932e070a683ac5fd82e698ec7d399b0ca61bd4e07f22542658a9b13efa340e4f000000ffffe3a70b7c1e9e0e0b0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"047228ad95cec16eb926f7cd21ac9cc9a3288d911a6c2917a24555eac7a2c0e2";
        blocksInfo[hash] = 1744859138;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180806000000e0773df8000000374944415478da6262a03118b560d482510b462d18b5806e165c62603006616ce254f3811e03c35986c1084653d1a805940340000000ffff94c80439947873b80000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180806000000e0773df80000002f4944415478da6262a03118b560d482510b462d18b5806e164c916250036142620302462379d482216001200000ffff8e55037f0295ca130000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"ce1f93a7afe9aad7ebb13c0add89c79d42b5e9b1272fdd1573aac99fe5d860d0";
        blocksInfo[hash] = 33542;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c5445000000000000692f08d8a2a9300000000174524e530040e6d866000000284944415478da62a01f608452018c0e202a34144c852d45e2318486322051a22170cd80000000ffffb3a4056366b432730000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"bfac272e71cad64427175cd77d774a7884f98c7901ebc4909ada29d464c8981e";
        blocksInfo[hash] = 2717948168;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c544500000028b143000000cc9ab8ec0000000174524e530040e6d8660000003e4944415478da62c00b181d5841142b03a3030303832803630003034308184129d6100686500718c508a218181802204a04c008041418280480000000ffff40c405ad8a2523500000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c544500000028b143000000cc9ab8ec0000000174524e530040e6d866000000474944415478da94c7b10d80300c05d18b447a0ad880411821856fff55906d898e825ff8f9f8d8bcf30eadd0cc5317a0c6cb704d1348a2604134477351ef0e6ccdcf3d010000ffffff6c099ea706747f0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"a71068a671b554f75b7cc31ce4f8d63c377f276333d11989e77bc4a9205b5e42";
        blocksInfo[hash] = 2164293896;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000000000a567b9cf0000000174524e530040e6d866000000294944415478daa4c0211100300800c097130b30b1280443109e3b2af0c6c547a0907838b63a0000ffff7250017908940adc0000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000000000a567b9cf0000000174524e530040e6d866000000294944415478da9cc0310d00300800b01ecbae65125042f02f8b9b971a2e3e0285c4c3b1d5010000ffff337800bd4717cafb0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"9a132de8409f80845eaec43154ff43d7bd61df75e52d96b4ded0b64626e4c88a";
        blocksInfo[hash] = 34056;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c5445000000794b11502f0566020e390000000174524e530040e6d8660000002a4944415478da62c0010244402463682806c5c2b56a558303036b686868a803480c22496300080000ffff65920776511a3f8f0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"fca4c5f86ef326916536dfdae74031d6960e41e10d38c624294334c3833974e2";
        blocksInfo[hash] = 26630;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180806000000e0773df80000002f4944415478da6262a03118b560d482510b462d18b560d40210602141ed4c2c62e90c030d462379045800080000ffff60530131658c7b950000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"4483a654781ca58fa6ba3590c74c005bce612263e17c70445d6cd167e55e900b";
        blocksInfo[hash] = 1795189516;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000d600002c63f04d0000000174524e530040e6d866000000134944415478da62201bf040317e00080000ffff03c000197c38ad200000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000d600002c63f04d0000000174524e530040e6d866000000134944415478da62a008f040316e00080000ffff0360001902542c490000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"1885fe71e225eade934ab7040d533bd49efc5d66e8f2d4b5aa42477ae9892ec9";
        blocksInfo[hash] = 2214626315;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180806000000e0773df80000004b4944415478da6262a03118b560d482510b869a0577efde6d180da2116801cd010b057affe31067c4c921c5f063c78e6108ca4c4d60905b7a0bc55c465afb806134990eb80580000000ffff78ff0b44c51816510000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180806000000e0773df80000004b4944415478da6262a03118b560d482510b869a0577efde6d180da2116801cd010b057affe31067c4c921c5f063c78e6108ca4c4d60905b7a0bc55c465afb806134990eb80580000000ffff78ff0b44c51816510000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"7411db1fe7a50d41767858710dc8b8432ac0c4fd26503ba78d2ed17789ce4f72";
        blocksInfo[hash] = 2113961226;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c544500000000000080dbda669cd55e0000000174524e530040e6d866000000224944415478da62a01608157560606060cc8c02510c99520e08416a0040000000ffff0567031c1296b7680000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c544500000000000080dbda669cd55e0000000174524e530040e6d866000000234944415478da62a03208157560606060cc8c02510c9952604a8495627301010000ffffca38028b89ad68880000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"dd7231e98344a83b64e1ac7a07b39d2ecc2b21128681123a9030e17a12422527";
        blocksInfo[hash] = 1946187018;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000000000a567b9cf0000000174524e530040e6d8660000001d4944415478da622005b0ff3fc0c0f0f90003436203b15a00010000ffffca27045b28df4bb90000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000000000a567b9cf0000000174524e530040e6d8660000001c4944415478da62200530ff6f6060f8dec0c0904cb41640000000ffff9e67035db5442bc60000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"24dd0364c2b2d0e6540c7deb5a0acf9177d47737a2bf41ca29b553eb69558ef9";
        blocksInfo[hash] = 2281735176;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b0000000c504c5445000000000000933709ca4e11586029880000000174524e530040e6d866000000264944415478da622005fcff032299ffff075152ab564d60606090debd7b0203ed01200000ffff89c6081c0afc0fac0000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b0000000c504c5445000000000000933709ca4e11586029880000000174524e530040e6d8660000002a4944415478da62200a888680a9fabf2092f1ff7f07060606b655ab2680a877ef2e30d01e00020000ffffcdba08c1f8ca1c3c0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"ea5efa009543229e434689349c866e4d254811928ae8a1320abb82a36d3be53f";
        blocksInfo[hash] = 33542;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180806000000e0773df80000004a4944415478da6262a03118b560d482510b462d18b5801e16f8d2c307be94388085488790ed13165214b784c9c2d935ab1e13a587910aaedf4c691c6c26d770ba80a19fd100010000ffff17b506cc6c8ffcb10000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"2df03e79022dc10f7539f01da354ffe10da3ef91f1e18bc7fd096db00c381de8";
        blocksInfo[hash] = 27137;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000000000a567b9cf0000000174524e530040e6d866000000124944415478da62a02a50c01001040000ffff02a00021e29936ae0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"f0ac7cf8c022008e16b983f22d22dae3a15b9b5abcc635bc5c20beb4d7c91800";
        blocksInfo[hash] = 36616;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b0000000c504c54450000000000003535355151511dd8d71d0000000174524e530040e6d866000000314944415478da62c00f42434024e3febf208aedff7f07060606f6afa10120ead6aa250c0c0caca11035340680000000ffff5f8a097e7a97a9b90000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"8580e735d58252637afd6fef159c826c5e7e6a5dcf1fe2d8398b3bf92c376d42";
        blocksInfo[hash] = 29958;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c5445000000a66e2c00000080c0c2990000000174524e530040e6d8660000001a4944415478da62185c80310099624a808836303000020000ffff12f9018505211f590000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"041bf83549434251cc54c0632896c8d3176b48d06150048c1bce6b6102c4e90c";
        blocksInfo[hash] = 1694524675;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180806000000e0773df80000002c4944415478da6262a03118b560d482510b462d18b5607858a0202796c63098c168248f5a403900040000ffff01a900e96b1795ed0000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180806000000e0773df80000002c4944415478da6262a03118b560d482510b462d18b560f858a0202796c63058c168248f5a403900040000fffffeb200e9e342816b0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"591f84c8a41edd0013624b89d5e6b96cd3b0c6f1e214d4ea13a35639412f07e6";
        blocksInfo[hash] = 38664;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000710cc759e1a3b70000000174524e530040e6d8660000003f4944415478da6cc6b10d40501000d017f989465cab905843c50a463a7b8bd368245ef57c1c741771d3174ba538d32e8dd83061c58019ed7df3eb090000fffff8b007a7fc0c1ce10000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"54917cb8cff2411930ac1b1d36a674f855c6b16c8662806266734b5f718a9890";
        blocksInfo[hash] = 29450;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000000000a567b9cf0000000174524e530040e6d8660000001b4944415478da62200530fe6760604a66606048265a0b200000ffff54c701c9074dcd420000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"274ae610f9d7dec1e425c54ad990e7d265ba95c4f84683be4333542088ecb8e7";
        blocksInfo[hash] = 28936;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180806000000e0773df8000000384944415478da6262a03118b5600458c042849a8978e4f229f5c1440ae5074710e553e20386d1643a6ac1a805a3168c5a400500080000ffff2ea40355b76925600000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"6a400b1508bfd84ab2f4cb067d6d74dc46f74cdae7efd8b2a2d990c9f037e426";
        blocksInfo[hash] = 2113961738;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b0000000c504c54450000000000005c390fc775146685ecb00000000174524e530040e6d866000000214944415478da62a012600c0d7500d1995260aa561e4c89b052cb7c40000000ffffe5a902a473b175720000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b0000000c504c54450000000000005c390fc775146685ecb00000000174524e530040e6d866000000204944415478da62a02e600c0d7500d1995260aa561e4c89b0526c30200000ffffd33402a4b41fa11a0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"3e6bc8fc06a569840c9490f8122e6b7f08a7598486649b64477b548602362516";
        blocksInfo[hash] = 2030074123;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b0000000c504c54450000000000005959590040ff401523b30000000174524e530040e6d8660000001b4944415478da621838c01aea00a2a4563b20f1700140000000ffff5249023a69668c5f0000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b0000000c504c54450000000000005959590040ff401523b30000000174524e530040e6d8660000001b4944415478da621838c01aea00a2a4563b20f1700140000000ffff5249023a69668c5f0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"2c382a7f1f32a6a2d0e9b0d378cb95e3dad70fe6909ff13888fe2a250bd10bb0";
        blocksInfo[hash] = 1778412293;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000dfdfdf337edd570000000174524e530040e6d866000000134944415478da62a015603c00a600010000ffff04e700c22f5ee81e0000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000dfdfdf337edd570000000174524e530040e6d866000000124944415478da62a01928009380000000ffff0300007135fa2b640000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"8968ce85cb55abb5d9f6f678baeeb565638b6bad5d9be0ea2e703a34f4593566";
        blocksInfo[hash] = 27137;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000000000a567b9cf0000000174524e530040e6d866000000124944415478da62a00a50c02903080000ffff03a0002126a77fa30000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"c3075202748482832362d1b854d8274a38bf56c5ad38d418e590f46113ff10b1";
        blocksInfo[hash] = 2466288394;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180403000000125920cb0000000f504c5445000000000000690c458c0d5bad21606331bdda0000000174524e530040e6d866000000324944415478da621828c02828c8282808e328290a2a29423982c6868cc6863019174746174798264101101a0c00100000ffffe5da0307c5d3f79f0000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180403000000125920cb0000000f504c5445000000000000690c458c0d5bad21606331bdda0000000174524e530040e6d866000000324944415478da62187c80515090515010c651521454528472048d0d198d0d61322e8e8c2e8e304d820220443f00080000ffff973e030740dbe40c0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"971f7c3d5d14436a3b5ef2d658445ea527464a6409bd5f9a44f3d72e30d1eba8";
        blocksInfo[hash] = 1979741448;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c544500000000000055555535d909f10000000174524e530040e6d8660000001a4944415478da6280034608c5e680856242911b0800080000ffff990c011c0109f9070000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c544500000000000055555535d909f10000000174524e530040e6d8660000001b4944415478da62c0051cc024e3042c1443030a8f2e00100000ffff765a0305a5b614880000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"1f7b5107846b1e32944ccf8aedeaa871fc859506f51e7d12d6e9ad594a4d7619";
        blocksInfo[hash] = 38664;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180403000000125920cb00000012504c54450000000060c3e4eb173cc300000000d604049007f3910000000174524e530040e6d866000000334944415478da622001300a0a22f15890d8824aaa0108554aaaa170092125a5d000b82a252475c6c6c6060c431600020000ffff8e2f043f67fbc8370000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"d35b2735e5fcc86991c8501996742b3b8c35772d92b69859de58ddd3559be46c";
        blocksInfo[hash] = 2147516424;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c54450000008119b7b261dc8e83430a0000000174524e530040e6d866000000254944415478da62c00f4243402463682a88620d8d84506051d6d0d05006ba0140000000fffff131041f8da125b90000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c54450000008119b7b261dc8e83430a0000000174524e530040e6d866000000254944415478da62200a888682a9d04807060606c6d03008151a0aa51c18680e00010000fffffb9604856eb921470000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"2004722753f61acb2cefde9b14d2c01c6bcb589d749b4ea616b4e47d83fdb056";
        blocksInfo[hash] = 2214623748;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b0000000c504c544500000028b1432c95412964343ee6dbfc0000000174524e530040e6d8660000001c4944415478da62a016106001531a5c608a871959900a00100000ffff23b6006aaf575b4b0000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180403000000125920cb0000000f504c544500000028b1432c95410000002964344cdbc5fd0000000174524e530040e6d866000000234944415478da6218848091814100ce615260508273981d184cb02ba33700040000ffff7ae900dec03f69060000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"05a5afe13f23e20e6cebabae910a492c91f4b862c2e1a5822914be79ab519bd8";
        blocksInfo[hash] = 32518;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c544500000000000086581eeeb664cd0000000174524e530040e6d866000000244944415478da62a01f6084520e6006636828980a5b0a1685f0184443706806040000ffff718d02fe68c219c00000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"ac5194b2986dd9939aedf83029a6e0a1d7d482eb00a5dafa05fc0aaa9b616582";
        blocksInfo[hash] = 2181072139;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c5445000000c9c9c9b1b1b1dfe0055e0000000174524e530040e6d8660000002a4944415478da62a0096081508c50ae0384213a0542858029d508b092d0506441d6001c2602020000ffff944e033f6ebf94330000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c5445000000c9c9c9b1b1b1dfe0055e0000000174524e530040e6d866000000274944415478da62a0256084d20e1086e814081502a65423c0546828b2206b000ea300010000ffff92de033acd8c71070000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"f94798c1aedb2dce1990e0dae94c15178ddd4229aff8031c9a5b7a77743a34d4";
        blocksInfo[hash] = 32518;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c5445000000a66e2c00000080c0c2990000000174524e530040e6d866000000244944415478da62a01f6084520e6006636828980a5b0a1685f0184443706806040000ffff718d02fe68c219c00000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"15854f7a2b735373aa76722c01e2f289d8b18cb1a70575796be435e4ce55e57a";
        blocksInfo[hash] = 2248181258;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b0000000c504c54450000000000008d8d8db4b4b44f7060b00000000174524e530040e6d866000000284944415478da62a01884863a30303030eeff3f81818181ed6ae805040515842aa10800020000ffff69b20a7394f432b40000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b0000000c504c54450000000000008d8d8db4b4b44f7060b00000000174524e530040e6d866000000284944415478da62a032080d7560606060dcff7f02030303dbd5d00b080a2a0855422200040000ffffd7670a737ec363890000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"d91f640608a7c1b2b750276d97d603512a02f4b84ca13c875a585b12a24320c2";
        blocksInfo[hash] = 1912631818;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000000000a567b9cf0000000174524e530040e6d8660000001a4944415478da62201630fe676060f800c509446b03040000ffffa0210341317dad5b0000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000000000a567b9cf0000000174524e530040e6d8660000001a4944415478da62200530fe676060f800c509446901040000ffff932103411ff574e90000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"6bb15b5e619a28950bae0eb6a03f13daea1b430ef5ded0c5606b335f5b077cda";
        blocksInfo[hash] = 2751501576;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000000000a567b9cf0000000174524e530040e6d8660000003d4944415478da624006ccfc0d0cc2ff0d18e4ff3f6090ffff81811f447f7ec0603ff300033fc303067986070ce20c20f601060e0607062200200000ffffb9320f35dcea59b30000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000000000a567b9cf0000000174524e530040e6d8660000004c4944415478da62800326060626970606d6fc090ce2ff1730f0ff7fc020ffff0384fe7c80c17ee603067e860f0cf20c0f18c419206c2e0607062606070616060706060605062c00100000ffff1b1511db1ceba4170000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"7a8b4abb14bfe7b505902c23a9c4e59e5a70c7daf6e28a5f83049c13142cde5e";
        blocksInfo[hash] = 35080;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c5445000000000000dc1d1d9b9a25510000000174524e530040e6d8660000002e4944415478da628001c6d05010c51a1aea808be25ab5aa818181413434348081812134343484816e00100000ffff612d08a80a65c2450000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"72efa89c7645580b2d0d03f51f1a2b64a425844a5cd69f1b3bb6609a4a06e47f";
        blocksInfo[hash] = 2399178504;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b0000000c504c54450000001a43c81637a4142c7c2bcdbdcc0000000174524e530040e6d866000000314944415478da62200aac5a05229942431b18181838c1145beeaa30060606c60d0c2b40d401b03a46065a0140000000ffff35c90742649028070000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b0000000c504c54450000001a43c81637a4142c7c2bcdbdcc0000000174524e530040e6d866000000314944415478da622005ac5a05229942431b18181838c1145beeaa30060606c60d0c2b40d401b03a4606aa0340000000ffff03020742f02d25cf0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"fc1c0134d4441a1d7c81368f23d7dfcdeab3776687073c12af9d268e00d6c0a8";
        blocksInfo[hash] = 29446;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c5445000000c28946a66e2cc99988650000000174524e530040e6d866000000184944415478da621830c0b6044c717020533801200000ffff22f000cb47eae9030000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"6ced067c29d04b367c1f3cb5e7721ad5a662f5e338ee3e10c7d64d9d109ed606";
        blocksInfo[hash] = 2533396488;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c54450000000000002a2a2a02692f080000000174524e530040e6d866000000354944415478da62c00142434024636a2888629d1aeac0c0c0201a1a1a80490542284710c920cae000d600318495816a00100000ffff912107d1f05714420000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c54450000000000002a2a2a02692f080000000174524e530040e6d8660000003c4944415478da62c00f42434024636a2888629d1aeac0c0c0201a1a1a8049054228c70001903606071130c58044854028113825c0403c00040000ffffd90d09b1ff89a89f0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"66a6c35fd6db8b93449f29befe26e2e4bcb09799d56216ada0ef901c53cf439f";
        blocksInfo[hash] = 2634063368;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c5445000000e226260000001337790f0000000174524e530040e6d866000000434944415478da6240038c0c0e208ad5350044b386ba82a8d0d0d000060616d1d0d05090586868084830c005240756c7c01800d19d0031054a39408da40200040000ffff0b6408c6ffc386f40000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000e226261ed2bbd80000000174524e530040e6d866000000454944415478da6240011a0c0c4c2b191898ea0b1858ff3730b0fd7fc020dedcc0c0cff081819de101031bc307061e86040616060730cdc6e0c0c0c4e0c0800700020000ffff86820ac86b32f7cc0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"85c5daead3bc85feb0d62d1f185f82fdc2627bdbc7f1f2ffed1c721c6fcc4b4d";
        blocksInfo[hash] = 38664;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180403000000125920cb0000000f504c544500000000000026314affffffffd8001025743b0000000174524e530040e6d866000000364944415478da622005080a2098824a8a302ea392928a9292229ca304e7300883004c97a010920c03a3a0a0a020c3500580000000ffff347603a082b51cae0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"3d1f5637dfc56d4147818053fdcc0c0a35886121b7e4fc1a7cff584e4bb6414f";
        blocksInfo[hash] = 27137;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000ffffffa5d99fdd0000000174524e530040e6d866000000124944415478da62a01a10c12a0a080000ffff02180015518fefb80000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"64b53b34ebe074820dbda2f80085c52f209d5eba6c783abdae0a19950f0787ec";
        blocksInfo[hash] = 31240;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c54450000004c4c4c63636367c20ce50000000174524e530040e6d8660000001f4944415478da62200584868048c6d45030351542858632d00100020000ffff4d8702fb0f1c34300000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"833ca1b7f8f2ce28f7003fb78b72e259d5a484b13477ad8212edb844217225ac";
        blocksInfo[hash] = 31238;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c5445000000a66e2c00000080c0c2990000000174524e530040e6d8660000001f4944415478da621830c01a02a6585890798c01c814d302b86a40000000ffff2fa301ff0f47294e0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"44c2482a71c9d39dac1cf9a7daf6de80db79735c0042846cb9d47f85ccc3ba9b";
        blocksInfo[hash] = 1979739907;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180806000000e0773df8000000364944415478da6262a03118b560d4826166810301fec080d148a6d882018dc8a1958a1c466e300d8a7c3038cba0e1535400020000ffff98f50225e7db2e020000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180806000000e0773df80000003d4944415478da6262a03118b560d482510b28b0a027ca7e26d55d43134387761c0c68900c9af8601ad4ae1d14c134f88a8a41979b877e710d080000fffff2580c5583685c2e0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"4acd7797c5821ccc56add3739a55bcfd4e4cfd72b30274ec6c156b6c1d9185eb";
        blocksInfo[hash] = 35334;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c5445000000000000a66e2c9730e2d80000000174524e530040e6d8660000002f4944415478da62a03fd05a05229956ad9ac0c0c020b5820b4c4179108a11423184ad7200518ca10c0c80000000ffff51890b8e68fe91ee0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"c0ac7bb45040825a6d9a997dc99a6ec94027d27133145018c0561b880ecdb389";
        blocksInfo[hash] = 30984;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000000000a567b9cf0000000174524e530040e6d866000000214944415478da62c009fe313030ce656060e480605c8011861bb04a03020000ffff7e1c023207c1f3860000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"a756817780c8e400f79cdd974270d70e0cd172aa662d7cf7c9fe0b63a4a71d95";
        blocksInfo[hash] = 32264;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000000000a567b9cf0000000174524e530040e6d866000000264944415478da620083100606867f10ccf89f8181f1230303b3650303830003a500100000ffff8fa8050f2a3982bb0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"71c5ce05a579f7a6bbc9fb7517851ae9394c8cb6e4fcad99245ce296b6a3c541";
        blocksInfo[hash] = 32518;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c5445000000a66e2c00000080c0c2990000000174524e530040e6d866000000244944415478da62a01f6084520e8c481443000a251a02511300a69816c03503020000ffff46850284e24691b90000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"283597377fbec1d21fb9d58af5fa0c43990b1f7c2fc6168412ceb4837d9bf86c";
        blocksInfo[hash] = 34312;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c54450000003d2f1e000000c8d065ca0000000174524e530040e6d8660000002b4944415478da62c0014403c054680812c5181a0aa2b856ad6a008985824419434321a2340680000000ffff28a206e959ceed270000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"bb1f372f67259011c2e9e7346c8a03a11f260853a1fe248ddd29540219788747";
        blocksInfo[hash] = 1879076871;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c5445000000000000ffd926bf0c26860000000174524e530040e6d866000000154944415478da62a00348805002949801080000ffff1df8007172dffd610000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c5445000000000000ffd926bf0c26860000000174524e530040e6d866000000154944415478da62a0039080502c949801080000ffff07fc001da05932af0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"d5de5c20969a9e22f93842ca4d65bac0c0387225cee45a944a14f03f9221fd4a";
        blocksInfo[hash] = 2164294666;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180806000000e0773df80000004b4944415478da6262a03118b560d482510be860010b01f9ff2498c5488e050ca79ffd2d84b14da598fbb1884dc0e71026125dc588c3a58c0316070ca3c974d482510b86810580000000ffffcf460a37173d31500000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180806000000e0773df8000000484944415478da6262a03118b560d482510b8683052c04e4ff13690e23b916309c7ef6b710c6369562eec725466e103162e13312eb7abac401c368321db560d402da5b00080000ffffbe8c09370dfcbb5e0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"b040fea53c68833d052aa3e7c8552b04390371501b9976c938d3bd8ec66e4734";
        blocksInfo[hash] = 2684384520;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c5445000000ffffff1a6ed56fb0c5a50000000174524e530040e6d8660000001a4944415478da62201d3086868228a655ab18e80700010000ffffdec602021e01f4d60000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b0000000c504c5445000000000000ffffff1a6ed5d93a1bf30000000174524e530040e6d866000000424944415478da6220033830824846d110070606069655ab0418181844feff17015160c420808d0a61600845a14419c04c08c518c20062b242a900343b01010000ffff7f5108b501fb5fc90000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"74ca947c09f7b62348c4f3c81b91973356ec81529d6220ff891012154ce517c7";
        blocksInfo[hash] = 2835392779;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180806000000e0773df8000000704944415478da6262a03118b560d482510b462dc00276eedcd940330b6086235b42f3206218f27130b27df09f963ef8df1a28826ec97f2c988191121f802ca95eff06660ecc523080895312078c2043907df2f8f51706649a521fa00717dcf019477ec0cd66a45184c3cd05040000ffffe2512fe56a94b4330000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180806000000e0773df8000000704944415478da6262a03118b560d482510b462dc00276eedcd940330b6086235b42f3206218f27130b27df09f963ef8df1a28826ec97f2c988191121f802ca95eff06660ecc523080895312078c2043907df2f8f51706649a521fa00717dcf019477ec0cd66a45184c3cd05040000ffffe2512fe56a94b4330000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"30146eda149865d57c6ae9dac707d809120563fadb039d7bca3231041bea6b2e";
        blocksInfo[hash] = 2197848840;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000000000a567b9cf0000000174524e530040e6d8660000002b4944415478da62c0007f191818ff333030ff3fc0c0febf8181f9770303bbe70106860e067200200000ffff2b95085cdd2d2f2d0000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000000000a567b9cf0000000174524e530040e6d8660000002b4944415478da62c0007f191818ff333030ff3fc0c0febf8181f9770303bbe70106860e067200200000ffff2b95085cdd2d2f2d0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"8394d1b7af0d52a25908dc9123cc00aa0670debcac95a76c3e9a20dd6c7e7c23";
        blocksInfo[hash] = 31238;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c544500000068461f000000b80d8ed70000000174524e530040e6d8660000001f4944415478da621830c01a02a6585890798c01c814d302b86a40000000ffff2fa301ff0f47294e0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"eb787e7727b2d8d912a02d9ad4c30c964b40f4cebe754bb4d3bfb09959565c91";
        blocksInfo[hash] = 47880;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c544500000000000055555535d909f10000000174524e530040e6d866000000604944415478da7ccdb10dc4200c85e1df050c71d330c4817457d3c03414648334f194d12352bac4b2fc59966cf310212dfe53d5fc10d15dd38ffb007a2e3bd0305157aa6d60037e37f10b25bd62f35a9858d531cbfa50434f8b0dce000000ffffa30d1684d4b69ae10000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"6a36bcf4268827203e8a3f374b49c1ff69b62623e234e96858ff0f2d32fbf268";
        blocksInfo[hash] = 1778413573;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000ffc926d3ca64d80000000174524e530040e6d866000000184944415478da62a0366004110d0c0c0c0e602e200000ffff06ef00c28387215b0000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000ffc926d3ca64d80000000174524e530040e6d866000000124944415478da62a01928009380000000ffff0300007135fa2b640000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"2f237bd68c6e318a6d0aa26172032a8a73a5e0e968ad3d74ef1178e64d209b48";
        blocksInfo[hash] = 29958;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000a66e2cb134b2d70000000174524e530040e6d8660000001d4944415478da62a004308270230303e34106068683589500020000ffff340b0207ed983fca0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"ad07511765ae4becdc5300c486c7806cd661840b0670d0f6670e8c4014de37b0";
        blocksInfo[hash] = 1929409800;
        blockL[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000000000a567b9cf0000000174524e530040e6d8660000001d4944415478da62c00a0418181842a078110303c324067201200000ffff79f001ed2e0ca9360000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000000000a567b9cf0000000174524e530040e6d8660000001b4944415478da622008b4181818421918185631900300010000ffff41aa012a18d810ed0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"49e0947b696384a658eeca7f5746ffbdd90a5f5526f8d15e6396056b7a0dc8af";
        blocksInfo[hash] = 2080406538;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c5445000000000000d7d7d7dd6bdeda0000000174524e530040e6d866000000214944415478da62a012600c0d7500518e01208a3531024c4104a90100010000ffff324a03ab83e6711a0000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c5445000000000000d7d7d7dd6bdeda0000000174524e530040e6d866000000214944415478da62a02e600c0d7500518e01208a3531024c4104290280000000ffff18a403ab4ed4e1740000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"c1695b389d89c71dc7afd5111f17f6540b3a28261e4d2bf5631c1484f322fc68";
        blocksInfo[hash] = 2097184522;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b0000000c504c5445000000f0f0f0328dfdfd3232d47923120000000174524e530040e6d866000000214944415478da62a012600d0d7560606060ccaa07510c500a22480d00080000ffff5dd3042db0f16dd40000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b0000000c504c5445000000f0f0f0328dfdfd3232d47923120000000174524e530040e6d8660000001f4944415478da62a02e600c0d75005159f5208a014a4104290280000000ffff3f3b04294160e2b30000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"09c36cad1064f6107d2e3bef439f87a16c8ef2e95905a827b2ce7f111dd801d7";
        blocksInfo[hash] = 2214623748;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b0000000c504c54450000002858b12c5195293e64cf044ab90000000174524e530040e6d8660000001c4944415478da62a016106001531a5c608a871959900a00100000ffff23b6006aaf575b4b0000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180403000000125920cb0000000f504c54450000002858b12c5195000000293e648e458eca0000000174524e530040e6d866000000234944415478da6218848091814100ce615260508273981d184cb02ba33700040000ffff7ae900dec03f69060000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"eb92e34266f6fa01c275db8379f6a521f15ab6f96297fe3266df2fe6b0e1422e";
        blocksInfo[hash] = 2181071880;
        blockL[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b0000000c504c544500000000000085561ea66e2c6852a3220000000174524e530040e6d866000000264944415478da6240800030c978014cb143286908a57f004c31432886030c740780000000ffffcd2f05565fc3044d0000000049454e44ae426082";
        blockS[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b0000000c504c544500000000000085561ea66e2c6852a3220000000174524e530040e6d866000000244944415478da62c005442054099864fc02a6d82014f707881c943260a00300040000ffff252e04932174d5ed0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"1892c4c9cf47baf2c613f184114519fe8208c2bebabb732405aeac1c3031dc2b";
        blocksInfo[hash] = 2466250760;
        blockS[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b0000000c504c54450000002d6b6200000080dbda32008fdd0000000174524e530040e6d866000000354944415478da62200a888680a955ab4024d3bffd0d20ead77a30b5320b443186863a303030b03230e0a41889a6b00040000000ffff4bc30b42e46330a00000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"250be814c80d8ca10bbef531b679392db8221a6fab289a6b5e637df663f48699";
        blocksInfo[hash] = 2868903944;
        blockS[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b0000000c504c544500000000000022900000558084ff9e8a0000000174524e530040e6d8660000004d4944415478da6240078c0e608a7d0298927b02a6a4b780a9bcb76015bb7783d430be7b07a2d857ad0629656b6002530c0c208a098562234c4935302d01f318413c46060607346701020000ffff3d76119d224fcf200000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"cd87356aa78c4fcb95e51f57578570d377440e347e0869cf1b4749d5a26340b5";
        blocksInfo[hash] = 1778384897;
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000c42110a2e982d40000000174524e530040e6d866000000124944415478da62a01a90c12a0a080000ffff02c8001d72b777ad0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"4fa682c6066fcc513a0511418aa85a0037ac59a899e9491c512b63e253697a8c";
        blocksInfo[hash] = 1895825412;
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180806000000e0773df8000000384944415478da6262a03118b560d482510b462da09605da65536682302131b22db8da95934e8cd88080d154346ac1a80574b000100000ffffc4410bcb596becd80000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"36f07f03014f047728880d9f390629140a5e7c44477290695c4c1ddda356d365";
        blocksInfo[hash] = 2264924168;
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000000000a567b9cf0000000174524e530040e6d8660000002f4944415478da62c00bea181818fe333030fe6f60603ed8c0c0dc00c1ec0c58302312666e606067079b00080000ffffd1030b1b1e3ca1240000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"68107f52c261820bd73e4046eb3fb5d5a1e0926611562c07054a3b89334cef34";
        blocksInfo[hash] = 1912602629;
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000000000a567b9cf0000000174524e530040e6d8660000001a4944415478da62a03a70606060486060603000f300010000ffff08c000d178549d360000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"d395cf4acda004fbc9963f85c65bf3f190c2aceb0744a535d543bc261caf6ff0";
        blocksInfo[hash] = 2801795080;
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000fff68e5319653e0000000174524e530040e6d8660000004f4944415478da624001c20c0c0ce71d1898df3730b0d7fd60e0fdff8041feff0106f6c31f18f8955e30c8b31430f0305430c8305430f0301430c831043070332c60e06330606061c00a00010000ffff3f7f0e31b0bc620f0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"bad0fc475e9d35de67c426fc37eebb7fa38141bc2135fabd5504a911e1b05540";
        blocksInfo[hash] = 2634022920;
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000ffffffa5d99fdd0000000174524e530040e6d866000000454944415478da62c00a6c191818eb181818ff3b30b0ff5fc0c07cff0103fbca030cdc1d0f18d8390218b8581218e4181218d8180a18d8181c1838181418700040000000ffff367b0a7764b3c52f0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"d10bc0475e2a0eea9f6aca91e6e82c6416f894f27fc26bb0735f29b84c54a3e6";
        blocksInfo[hash] = 1979711496;
        blockS[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c5445000000ffba00ff2a00ec23aa7c0000000174524e530040e6d8660000001b4944415478da62201f888a40680730c9380199477500080000ffff7648013b91a176490000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"a0a2010e841ab7b343263c98f47a16b88656913e1353d96914f5fe492511893f";
        blocksInfo[hash] = 2315255816;
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000e65700fdf2de4e0000000174524e530040e6d866000000324944415478da62c0096c181818fe333030fe6f80e0d6030ccc0c10cc04c50c0c0f3031e303060666106e009902080000ffff4fd30f33b75f06fe0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"0e6769a10f786458ca82b57684746fe8899e35f7772543acb6a8869c4ac780cd";
        blocksInfo[hash] = 1929379848;
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000e226261ed2bbd80000000174524e530040e6d8660000001b4944415478da62c0001c0c0c0c120c0c0c16509a3200080000ffff1f400071228f4c0b0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"1004d2d00ccf8794739c7b7cbbe6048841f4c8af046b37d59e9a801a167544e2";
        blocksInfo[hash] = 1895825412;
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180806000000e0773df8000000384944415478da6262a03118b560d482510b462da09605db18d6cf04614262645be0c510984e8cd88080d154346ac1a80574b000100000ffff94270a2bdc4a43550000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"629e82a55845ea763431647fcaecfb232e275a36d8427f2568377864193801cb";
        blocksInfo[hash] = 2449473544;
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000000000a567b9cf0000000174524e530040e6d8660000003a4944415478da62c009ea181818fe333030fe6f6060fe7f0082273c60606780603686070c7c50cccff08141bef1030373e301745300010000ffffc5ab1058fff3c7650000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"cd3633a5e96d615b834e90e67029f7f9f507b832e1cb263a29685b8e25f678cf";
        blocksInfo[hash] = 2231369736;
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000fff68e5319653e0000000174524e530040e6d8660000002d4944415478da62c00a6a181818fe313030fe07e1060666106e696060e66860606280604646066200200000ffffdcdb0815f637cf1a0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"e81a9c78c0ec4339dc6772f1b9bbf406b53063f8408a91fe29f63ba1c2bc7b5a";
        blocksInfo[hash] = 1778384897;
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000cd00cb30a6a7e40000000174524e530040e6d866000000124944415478da62a01a90c12a0a080000ffff02c8001d72b777ad0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"e11278d6c191c8199a5b8bb49be7f806b837a9811195c903d844a74c4c4a704e";
        blocksInfo[hash] = 2600468488;
        blockS[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b00000009504c5445000000000000ffd926bf0c26860000000174524e530040e6d866000000404944415478da62200a888680c880d050560606c6b0d0d0a90e0caca1a1a1a1010cac81018cae010cac8e0e0c8c010cac0e0c208a11a4da81819a00100000ffff496407d2e13d1cb20000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"411ec1566affa22bd67b13a7c49ac060c018e1c806cd314cd2186118dd55e129";
        blocksInfo[hash] = 2281701384;
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000fff68e5319653e0000000174524e530040e6d866000000304944415478da7cccb10900300c03c1372ab475d06a99cc81b8f7c3b5cfda011aaa836e50865954b082fd0f2f0000ffffd0db0b19f8088baf0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"1868a04ecae06e10c5b6dcbbed4befac1ed03dda2cf86ddbd855466cc588809f";
        blocksInfo[hash] = 2197815306;
        blockS[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b0000000c504c54450000001c1a00534c0080dbda6080589f0000000174524e530040e6d866000000254944415478da62200364463930303030eecb6f40a232a5c0820c0c0e0cb40080000000ffff32d20565dbf243f00000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"3511b04ac6a3d46305172269904dc469a40f380a4e7afa8742ce6e6a44825c4a";
        blocksInfo[hash] = 2785017864;
        blockS[hash] = hex"89504e470d0a1a0a0000000d49484452000000180000001802030000009d19d56b0000000c504c5445000000ff8ebe000000ffffff4ae3beda0000000174524e530040e6d866000000484944415478da62200568ad0053ab578148a655af1ac0d42a10c5181aeac0c0c0c0ea181000a2181c409408034308030383281e8a958101acc1811144313a303a60b71a100000ffff0f6e0bf3e2fa2eec0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"2857e47dcac3b744dd7d41617ce362f1dd3ae8eb836685cc18338714205b036c";
        blocksInfo[hash] = 2432696328;
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000fff68e5319653e0000000174524e530040e6d866000000394944415478da62c00aea181818ff83700303f3df030ccc15071898050e30b0331c6060836276307e00c6fc0d1f18980f36603309100000ffffaa950e78c9a6ec2c0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"2e9a5434da70e5ea2ed439b3a33aac60bd252c92698c1ba37e9ed77f975c6cab";
        blocksInfo[hash] = 1895825412;
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180806000000e0773df8000000384944415478da6262a03118b560d482510b462da09605da531c6782302131b22db89ab33f9d18b10101a3a968d482510be86001200000ffffd02f0b616aa9c37e0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"8c0e60b85ff0f8be1a87b28ae066a63dcc3c02589a213b0856321a73882515f9";
        blocksInfo[hash] = 2264924168;
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c544500000051360c48b320160000000174524e530040e6d8660000002f4944415478da62c00bea181818fe333030fe6f60603ed8c0c0dc00c1ec0c58302312666e606067079b00080000ffffd1030b1b1e3ca1240000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"e651be5dd43261e6e9c1098ec114ab5c44e7cb07377dc674336f1b3d34428fe4";
        blocksInfo[hash] = 2382364680;
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000000000a567b9cf0000000174524e530040e6d866000000364944415478da62c00a0a1818187f303030bf6060607fc0c0c07e808181bd8181811f861920980f19373030c83320301400020000ffff746d06dbf514328c0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;

        hash = hex"1cd064e6db4e7c5180ccf5f2afe1370c6539b525fe3bea9c358f24a7cbdb50ad";
        blocksInfo[hash] = 1778384897;
        blockS[hash] = hex"89504e470d0a1a0a0000000d4948445200000018000000180103000000dab9afbb00000006504c5445000000000000a567b9cf0000000174524e530040e6d866000000124944415478da62a01a90c12a0a080000ffff02c8001d72b777ad0000000049454e44ae426082";
        index[nextId] = bytes32(hash);
        nextId++;



        // default config
        mapping(Layer => uint16) storage c = orderConfig[0];
        for (uint8 i = 0; i < 13; i++) {
            c[Layer(i)] = i;
        }
        nextConfigId++;

        admin = msg.sender;
    }

    function abort() external payable {
        require (msg.sender == admin, "nope");
        selfdestruct(payable(admin));
    }

    function seal() external {
        require (msg.sender == admin, "nope");
        admin = address(0);
    }

    function toString(uint256 value) public pure returns (string memory) {
        // Inspired by openzeppelin's implementation - MIT licence
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol#L15
        // this version removes the decimals counting
        uint8 count;
        if (value == 0) {
            return "0";
        }
        uint256 digits = 31;
        // bytes and strings are big endian, so working on the buffer from right to left
        // this means we won't need to reverse the string later
        bytes memory buffer = new bytes(32);
        while (value != 0) {
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
            digits -= 1;
            count++;
        }
        uint256 temp;
        assembly {
            temp := mload(add(buffer, 32))
            temp := shl(mul(sub(32,count),8), temp)
            mstore(add(buffer, 32), temp)
            mstore(buffer, count)
        }
        return string(buffer);
    }

}
// IAttrParser implemented by 0x4e776fCbb241a0e0Ea2904d642baa4c7E171a1E9
interface IAttrParser {
    function parseAttributes(uint256 _tokenId) external view returns (string[8] memory);
}

library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
        // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

        // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

        // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
            // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

            // To write each character, shift the 3 bytes (18 bits) chunk
            // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
            // and apply logical AND with 0x3F which is the number of
            // the previous character in the ASCII table prior to the Base64 Table
            // The result is then added to the table to get the character to write,
            // and finally write it in the result pointer but with a left shift
            // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

        // When data `bytes` is not exactly 3 bytes long
        // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }
        return result;
    }
}

/**
* DynamicBufferLib adapted from
* https://github.com/Vectorized/solady/blob/main/src/utils/DynamicBufferLib.sol
*/
library DynamicBufferLib {
    /// @dev Type to represent a dynamic buffer in memory.
    /// You can directly assign to `data`, and the `append` function will
    /// take care of the memory allocation.
    struct DynamicBuffer {
        bytes data;
    }

    /// @dev Appends `data` to `buffer`.
    /// Returns the same buffer, so that it can be used for function chaining.
    function append(DynamicBuffer memory buffer, bytes memory data)
    internal
    pure
    returns (DynamicBuffer memory)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if mload(data) {
                let w := not(31)
                let bufferData := mload(buffer)
                let bufferDataLength := mload(bufferData)
                let newBufferDataLength := add(mload(data), bufferDataLength)
            // Some random prime number to multiply `capacity`, so that
            // we know that the `capacity` is for a dynamic buffer.
            // Selected to be larger than any memory pointer realistically.
                let prime := 1621250193422201
                let capacity := mload(add(bufferData, w))

            // Extract `capacity`, and set it to 0, if it is not a multiple of `prime`.
                capacity := mul(div(capacity, prime), iszero(mod(capacity, prime)))

            // Expand / Reallocate memory if required.
            // Note that we need to allocate an exta word for the length, and
            // and another extra word as a safety word (giving a total of 0x40 bytes).
            // Without the safety word, the data at the next free memory word can be overwritten,
            // because the backwards copying can exceed the buffer space used for storage.
                for {} iszero(lt(newBufferDataLength, capacity)) {} {
                // Approximately double the memory with a heuristic,
                // ensuring more than enough space for the combined data,
                // rounding up to the next multiple of 32.
                    let newCapacity :=
                    and(add(capacity, add(or(capacity, newBufferDataLength), 32)), w)

                // If next word after current buffer is not eligible for use.
                    if iszero(eq(mload(0x40), add(bufferData, add(0x40, capacity)))) {
                    // Set the `newBufferData` to point to the word after capacity.
                        let newBufferData := add(mload(0x40), 0x20)
                    // Reallocate the memory.
                        mstore(0x40, add(newBufferData, add(0x40, newCapacity)))
                    // Store the `newBufferData`.
                        mstore(buffer, newBufferData)
                    // Copy `bufferData` one word at a time, backwards.
                        for { let o := and(add(bufferDataLength, 32), w) } 1 {} {
                            mstore(add(newBufferData, o), mload(add(bufferData, o)))
                            o := add(o, w) // `sub(o, 0x20)`.
                            if iszero(o) { break }
                        }
                    // Store the `capacity` multiplied by `prime` in the word before the `length`.
                        mstore(add(newBufferData, w), mul(prime, newCapacity))
                    // Assign `newBufferData` to `bufferData`.
                        bufferData := newBufferData
                        break
                    }
                // Expand the memory.
                    mstore(0x40, add(bufferData, add(0x40, newCapacity)))
                // Store the `capacity` multiplied by `prime` in the word before the `length`.
                    mstore(add(bufferData, w), mul(prime, newCapacity))
                    break
                }
            // Initalize `output` to the next empty position in `bufferData`.
                let output := add(bufferData, bufferDataLength)
            // Copy `data` one word at a time, backwards.
                for { let o := and(add(mload(data), 32), w) } 1 {} {
                    mstore(add(output, o), mload(add(data, o)))
                    o := add(o, w) // `sub(o, 0x20)`.
                    if iszero(o) { break }
                }
            // Zeroize the word after the buffer.
                mstore(add(add(bufferData, 0x20), newBufferDataLength), 0)
            // Store the `newBufferDataLength`.
                mstore(bufferData, newBufferDataLength)
            }
        }
        return buffer;
    }
/*
    /// @dev Appends `data0`, `data1` to `buffer`.
    /// Returns the same buffer, so that it can be used for function chaining.
    function append(DynamicBuffer memory buffer, bytes memory data0, bytes memory data1)
    internal
    pure
    returns (DynamicBuffer memory)
    {
        return append(append(buffer, data0), data1);
    }
*/
    /// @dev Appends `data0`, `data1`, `data2` to `buffer`.
    /// Returns the same buffer, so that it can be used for function chaining.
    function append(
        DynamicBuffer memory buffer,
        bytes memory data0,
        bytes memory data1,
        bytes memory data2
    ) internal pure returns (DynamicBuffer memory) {
        return append(append(append(buffer, data0), data1), data2);
    }
/*

    /// @dev Appends `data0`, `data1`, `data2`, `data3` to `buffer`.
    /// Returns the same buffer, so that it can be used for function chaining.
    function append(
        DynamicBuffer memory buffer,
        bytes memory data0,
        bytes memory data1,
        bytes memory data2,
        bytes memory data3
    ) internal pure returns (DynamicBuffer memory) {
        return append(append(append(append(buffer, data0), data1), data2), data3);
    }

    /// @dev Appends `data0`, `data1`, `data2`, `data3`, `data4` to `buffer`.
    /// Returns the same buffer, so that it can be used for function chaining.
    function append(
        DynamicBuffer memory buffer,
        bytes memory data0,
        bytes memory data1,
        bytes memory data2,
        bytes memory data3,
        bytes memory data4
    ) internal pure returns (DynamicBuffer memory) {
        append(append(append(append(buffer, data0), data1), data2), data3);
        return append(buffer, data4);
    }

    /// @dev Appends `data0`, `data1`, `data2`, `data3`, `data4`, `data5` to `buffer`.
    /// Returns the same buffer, so that it can be used for function chaining.
    function append(
        DynamicBuffer memory buffer,
        bytes memory data0,
        bytes memory data1,
        bytes memory data2,
        bytes memory data3,
        bytes memory data4,
        bytes memory data5
    ) internal pure returns (DynamicBuffer memory) {
        append(append(append(append(buffer, data0), data1), data2), data3);
        return append(append(buffer, data4), data5);
    }

    /// @dev Appends `data0`, `data1`, `data2`, `data3`, `data4`, `data5`, `data6` to `buffer`.
    /// Returns the same buffer, so that it can be used for function chaining.
    function append(
        DynamicBuffer memory buffer,
        bytes memory data0,
        bytes memory data1,
        bytes memory data2,
        bytes memory data3,
        bytes memory data4,
        bytes memory data5,
        bytes memory data6
    ) internal pure returns (DynamicBuffer memory) {
        append(append(append(append(buffer, data0), data1), data2), data3);
        return append(append(append(buffer, data4), data5), data6);
    }
    */
}