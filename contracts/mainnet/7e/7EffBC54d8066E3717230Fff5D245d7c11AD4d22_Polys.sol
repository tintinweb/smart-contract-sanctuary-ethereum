//"SPDX-License-Identifier: GPL-3.0

/*******************************************
              _                       _
             | |                     | |
  _ __   ___ | |_   _ ___   __ _ _ __| |_
 | '_ \ / _ \| | | | / __| / _` | '__| __|
 | |_) | (_) | | |_| \__ \| (_| | |  | |_
 | .__/ \___/|_|\__, |___(_)__,_|_|   \__|
 | |             __/ |
 |_|            |___/

 a homage to math, geometry and cryptography.

********************************************/
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./SSTORE2.sol";
import "./Base64.sol";
import "./PolyRenderer.sol";


contract Polys is ERC721, ReentrancyGuard, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;
    using Base64 for bytes;

    // Token structs and types
    // -------------------------------------------
    enum TokenType {Original, Offspring, Circle}

    struct Parents {
        uint16 polyIdA;
        uint16 polyIdB;
    }

    struct TokenMetadata {
        string name;
        address creator;
        uint8 remainingChildren;
        bool wasCircled;
        TokenType tokenType;
    }

    struct Counters {
        uint8 originals;
        uint16 offspring;
    }

    // Events
    // -------------------------------------------
    event AuctionStarted(uint256 startTime);
    event BreedingStarted();
    event CirclingStarted();

    // Constants
    // -------------------------------------------
    // all eth in this wallet will be used for charity actions
    address private constant _charityWallet = 0xE00327f0f5f5F55d01C2FC6a87ddA1B8E292Ac79;

    uint8 private constant _MAX_NUM_ORIGINALS = 100;
    uint8 private constant _MAX_NUM_OFFSPRING = 16;
    uint8 private constant _MAX_PER_EARLY_ACCESS_ADDRESS = 4;
    uint8 private constant _MAX_CIRCLES_PER_WALLET = 5;

    uint private constant _START_PRICE = 16 ether;
    uint private constant _RESERVE_PRICE = 0.25 ether;
    uint private constant _AUCTION_DURATION = 1 days;
    uint private constant _HALVING_PERIOD = 4 hours; // price halves every halving period


    // State variables
    // -------------------------------------------

    // We always return the on-chain image, but currently some platforms can't render on-chain images
    // so we will also provide an off-chain version. Once the majority of the platforms upgrade and start rendering
    // on-chain images, we will stop providing the off-chain version.
    bool private _alsoShowOffChainVersion;

    // We might want to add the animation we used on the website to the NFT itself sometime in the future.
    bool private _alsoShowAnimationUrl;

    uint public auctionStartTime;
    bool public isBreedingSeason;
    bool public isCirclingSeason;
    mapping(address => uint) public availableBalance;

    Counters private _counters;
    mapping(address => uint) private _circlesMinted;

    address private _openSeaProxyRegistryAddress;
    bool private _isOpenSeaProxyActive = true;
    string private _baseUrl = "https://polys.art/poly/";

    // Original Variables
    // -------------------------------------------
    // @dev only originals have data
    mapping(uint256 => TokenMetadata) public tokenMetadata;
    mapping(uint256 => address) private _tokenDataPointers;
    mapping(address => string) private _creatorsName;

    // Offspring Variables
    // -------------------------------------------
    mapping(uint256 => Parents) private _tokenIdToParents;
    mapping(bytes32 => bool) private _tokenPairs;
    mapping(address => uint8) private _mintedOnPreSale;

    constructor(address openSeaProxyRegistryAddress) ERC721("Polys", "POLY") {
        _openSeaProxyRegistryAddress = openSeaProxyRegistryAddress;
    }

    // Creation Functions
    // -------------------------------------------
    function mint(bytes calldata polyData, string calldata name, uint256 tokenId,
        address creator, bytes calldata signature) nonReentrant payable external {
        require(tokenId <= _MAX_NUM_ORIGINALS && tokenId > 0, "1");
        require(verify(abi.encodePacked(polyData, name, tokenId, creator), signature), "2");
        require(polyData.length > 19 && polyData.length < 366, "3");
        require(polyData.length % 5 == 0, "4");
        require(bytes(name).length > 0 && bytes(name).length < 11, "5");
        require(auctionStartTime != 0, "13");

        if (msg.sender != creator) {
            require(msg.value >= price(), "6");
            uint256 tenPercent = msg.value / 10;
            availableBalance[owner()] += tenPercent;
            availableBalance[creator] += (msg.value-tenPercent);
        } else if (msg.sender != owner()) {
            // artists can mint their own pieces for 10%, and the founder can mint his pieces for free
            // so in practise each artist sets the minimum price of their NFTs,
            // if price goes lower than their minimum, they will mint them themselves.
            require(msg.value >= (price() / 10), "6");
            availableBalance[owner()] += msg.value;
        }

        TokenMetadata memory metadata;
        metadata.name = name;
        metadata.remainingChildren = _MAX_NUM_OFFSPRING;
        metadata.creator = creator;
        metadata.tokenType = TokenType.Original;

        // SSTORE2 significantly reduces the gas costs. Kudos to hypnobrando for showing me this solution.
        _tokenDataPointers[tokenId] = SSTORE2.write(polyData);
        tokenMetadata[tokenId] = metadata;
        _counters.originals += 1;

        _mint(msg.sender, tokenId);
    }

    // State changing functions
    // -------------------------------------------
    function startAuction() external onlyOwner {
        require(auctionStartTime == 0); // can't start the auction twice.
        auctionStartTime = block.timestamp;
        emit AuctionStarted(auctionStartTime);
    }

    function alsoShowOffChainVersion(bool state) external onlyOwner {
        _alsoShowOffChainVersion = state;
    }

    function alsoShowAnimationUrl(bool state) external onlyOwner {
        _alsoShowAnimationUrl = state;
    }

    function setBaseUrl(string calldata baseUrl) external onlyOwner {
        _baseUrl = baseUrl;
    }

    function startBreedingSeason() public onlyOwner {
        isBreedingSeason = true;
        emit BreedingStarted();
    }

    function startCirclingSeason() public onlyOwner {
        isCirclingSeason = true;
        emit CirclingStarted();
    }

    function signPieces(string calldata name) public {
        require(bytes(name).length < 16);
        _creatorsName[msg.sender] = name;
    }

    // Disable gas-less listings to OpenSea. Kudos to Crypto Coven!
    function setIsOpenSeaProxyActive(bool isOpenSeaProxyActive) external onlyOwner {
        _isOpenSeaProxyActive = isOpenSeaProxyActive;
    }

    // Circling and Mixing
    // -------------------------------------------
    function mintCircle(uint256 polyId) external nonReentrant payable {
        require(isCirclingSeason, "7");
        require(tokenIsOriginal(polyId), "8");
        require(tokenMetadata[polyId].wasCircled == false, "9");
        require(msg.value == 0.314 ether, "6");
        require(_circlesMinted[msg.sender] < _MAX_CIRCLES_PER_WALLET);
        _circlesMinted[msg.sender] += 1;

        uint256 circleTokenId = _MAX_NUM_ORIGINALS + polyId;

        tokenMetadata[polyId].wasCircled = true;

        _safeMint(msg.sender, circleTokenId);

        availableBalance[creatorOf(polyId)] += 0.2512 ether;
        availableBalance[owner()] += 0.0314 ether;
        availableBalance[_charityWallet] += 0.0314 ether;
    }

    function preSaleOffspring(uint256 polyIdA, uint256 polyIdB, bytes calldata signature) external nonReentrant payable {
        require(_mintedOnPreSale[msg.sender] < _MAX_PER_EARLY_ACCESS_ADDRESS, "10");
        require(verify(abi.encodePacked(msg.sender), signature), "2");
        _mintedOnPreSale[msg.sender] += 1;
        _mintOffspring(polyIdA, polyIdB);
    }

    function publicSaleOffspring(uint256 polyIdA, uint256 polyIdB) external nonReentrant payable {
        require(isBreedingSeason, "11");
        _mintOffspring(polyIdA, polyIdB);
    }

    // Internal
    // -------------------------------------------
    function verify(bytes memory message, bytes calldata signature) internal view returns (bool){
        return keccak256(message).toEthSignedMessageHash().recover(signature) == owner();
    }

    function description(bool isCircle) internal pure returns (string memory) {
        string memory shape = isCircle ? '"Circles' : '"Regular polygons';
        return string(abi.encodePacked(shape, ' on an infinitely scalable canvas."'));
    }

    // Shout out to blitmap for coming up with this breeding mechanic
    function _mintOffspring(uint256 polyIdA, uint256 polyIdB) internal {
        require(tokenIsOriginal(polyIdA) && tokenIsOriginal(polyIdB), "16");
        require(polyIdA != polyIdB, "17");
        require(tokenMetadata[polyIdA].remainingChildren > 0, "18");
        require(msg.value == 0.08 ether, "6");

        // a given pair can only be minted once
        bytes32 pairHash = keccak256(abi.encodePacked(polyIdA, polyIdB));
        require(_tokenPairs[pairHash] == false, "19");

        _counters.offspring += 1;
        uint256 offspringTokenId = 2 * _MAX_NUM_ORIGINALS + _counters.offspring;

        Parents memory parents;
        parents.polyIdA = uint16(polyIdA);
        parents.polyIdB = uint16(polyIdB);

        tokenMetadata[polyIdA].remainingChildren--;

        _tokenIdToParents[offspringTokenId] = parents;
        _tokenPairs[pairHash] = true;
        _safeMint(msg.sender, offspringTokenId);

        availableBalance[creatorOf(polyIdA)] += 0.056 ether;
        availableBalance[creatorOf(polyIdB)] += 0.008 ether;
        availableBalance[owner()] += 0.008 ether;
        availableBalance[_charityWallet] += 0.008 ether;
    }

    // Withdraw
    // -------------------------------------------
    function withdraw() public nonReentrant {
        uint256 withdrawAmount = availableBalance[msg.sender];
        availableBalance[msg.sender] = 0;
        (bool success,) = msg.sender.call{value: withdrawAmount}('');
        require(success, "12");
    }

    // Getters
    // -------------------------------------------
    function numMintedOriginals() public view returns (uint) {
        return _counters.originals;
    }

    function pairIsTaken(uint256 polyIdA, uint256 polyIdB) public view returns (bool) {
        bytes32 pairHash = keccak256(abi.encodePacked(polyIdA, polyIdB));
        return _tokenPairs[pairHash];
    }

    function price() public view returns (uint256) {
        require(block.timestamp >= auctionStartTime);
        uint timeElapsed = block.timestamp - auctionStartTime; // timeElapsed since start of the auction
        if (timeElapsed > _AUCTION_DURATION)
            return _RESERVE_PRICE;
        uint period = timeElapsed/_HALVING_PERIOD;
        uint start_price = _START_PRICE >> period;  // start price for current period
        uint end_price = _START_PRICE >> (period + 1);  // end price for current period
        timeElapsed = timeElapsed % _HALVING_PERIOD; // timeElapsed since the start of the current period
        return ((_HALVING_PERIOD - timeElapsed)*start_price + timeElapsed * end_price)/_HALVING_PERIOD;
    }

    function parentOfCircle(uint circleId) public view returns (uint256){
        require(tokenIsCircle(circleId), "14");
        return circleId - _MAX_NUM_ORIGINALS;
    }

    function creatorNameOf(uint polyId) public view returns(string memory){
        return _creatorsName[creatorOf(polyId)];
    }

    function creatorOf(uint polyId) public view returns (address){
        uint tokenId;
        if (tokenIsOriginal(polyId)){
            tokenId = polyId;
        } else if (tokenIsCircle(polyId)){
            tokenId = parentOfCircle(polyId);
        } else {
            tokenId = _tokenIdToParents[polyId].polyIdA;
        }
        return tokenMetadata[tokenId].creator;
    }

    function tokenIsOriginal(uint256 polyId) public view returns (bool) {
        return _exists(polyId) && (polyId <= _MAX_NUM_ORIGINALS);
    }

    function tokenIsCircle(uint256 polyId) public view returns (bool) {
        return _exists(polyId) && polyId > _MAX_NUM_ORIGINALS && polyId <= 2*_MAX_NUM_ORIGINALS;
    }

    function parentsOfMix(uint256 mixId) public view returns (uint256, uint256) {
        require(!tokenIsOriginal(mixId) && !tokenIsCircle(mixId));
        return (_tokenIdToParents[mixId].polyIdA, _tokenIdToParents[mixId].polyIdB);
    }

    function tokenNameOf(uint polyId) public view returns (string memory) {
        require(_exists(polyId), "15");
        if (tokenIsOriginal(polyId)) {
            return tokenMetadata[polyId].name;
        }
        if (tokenIsCircle(polyId)) {
            return string(abi.encodePacked("Circled ", tokenMetadata[parentOfCircle(polyId)].name));
        }
        Parents memory parents = _tokenIdToParents[polyId];
        return string(abi.encodePacked(tokenMetadata[parents.polyIdA].name, " ",
            tokenMetadata[parents.polyIdB].name));
    }

    function tokenDataOf(uint256 polyId) public view returns (bytes memory) {
        if (tokenIsOriginal(polyId)) {
            return SSTORE2.read(_tokenDataPointers[polyId]);
        }
        if (tokenIsCircle(polyId)) {
            return SSTORE2.read(_tokenDataPointers[parentOfCircle(polyId)]);
        }
        bytes memory composition = SSTORE2.read(_tokenDataPointers[_tokenIdToParents[polyId].polyIdA]);
        bytes memory palette = SSTORE2.read(_tokenDataPointers[_tokenIdToParents[polyId].polyIdB]);

        // Is the first palette colour equal to the background color:
        bool compositionUsesNegativeTechnique = (composition[0] == composition[3]) && (composition[1] == composition[4])
                                                && (composition[2] == composition[5]);
        // Some compositions use a few polys with the colour of the background to remove foreground from the image.
        // We call this, the "negative technique", because adding polys subtracts foreground instead of adding.
        // For this technique to be correctly translated to mixings, we do two things:
        // 1) we ordered (off-chain) all the colours in the palette according to their distance to the background color
        // so that the most similar colour to the background is the first.
        // 2) if the composition uses the "negative technique", then on the palette we replace the closest colour to the
        // background with the actual background so that this technique is applied perfectly.

        for (uint8 i = 0; i < 15; ++i) {
            if (compositionUsesNegativeTechnique && i > 2 && i < 6){
                // make the first palette colour the same as the background
                composition[i] = palette[i-3];
            } else {
                composition[i] = palette[i];
            }
        }
        return composition;
    }

    function tokenURI(uint polyId) override public view returns (string memory) {
        require(_exists(polyId), "15");
        bytes memory polyData = tokenDataOf(polyId);
        bool isCircle = tokenIsCircle(polyId);
        string memory idStr = polyId.toString();
        string memory svg = PolyRenderer.svgOf(polyData, isCircle);

        bytes memory media = abi.encodePacked('data:image/svg+xml;base64,', bytes(svg).encode());
        if (_alsoShowOffChainVersion) {
            media = abi.encodePacked(',"image_data":"', media, '","image":"', _baseUrl, idStr);
        } else {
            media = abi.encodePacked(',"image":"', media);
        }
        if (_alsoShowAnimationUrl) {
            media = abi.encodePacked(',"animation_url":"', _baseUrl, "anim/", idStr, '"', media);
        }

        string memory json = abi.encodePacked('{"name":"#', idStr, " ", tokenNameOf(polyId),
            '","description":', description(isCircle), media, '","attributes":',
            PolyRenderer.attributesOf(polyData, isCircle), '}').encode();
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    // Allow gas-less listings on OpenSea.
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        ProxyRegistry proxyRegistry = ProxyRegistry(
            _openSeaProxyRegistryAddress
        );
        if (_isOpenSeaProxyActive && address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }
}

// Used to Allow gas-less listings on OpenSea
contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/*
errors:
1: Original token id should be between 1 and 100.
2: Invalid signature.
3: Poly data length should be between 20 and 365 bytes.
4: Poly data length should be a multiple of 5.
5: The poly name needs to be between 1 and 10 characters.
6: ETH value is incorrect.
7: It is not circle season.
8: Token id is not original.
9: That parent was already circled.
10: No more pre-sale mints left.
11: It is not breeding season.
12: Withdraw failed.
13: Auction has not started yet.
14: That token is not a circle.
15: Poly does not exist.
16: One or two parents are not original
17: The parents can't be the same.
18: The first parent has 0 remaining children
19: That combination was already minted.
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Bytecode {
    error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

    /**
      @notice Generate a creation code that results on a contract with `_code` as bytecode
      @param _code The returning value of the resulting `creationCode`
      @return creationCode (constructor) for new contract
    */
    function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
        /*
          0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
          0x01    0x80         0x80        DUP1                size size
          0x02    0x60         0x600e      PUSH1 14            14 size size
          0x03    0x60         0x6000      PUSH1 00            0 14 size size
          0x04    0x39         0x39        CODECOPY            size
          0x05    0x60         0x6000      PUSH1 00            0 size
          0x06    0xf3         0xf3        RETURN
          <CODE>
        */

        return abi.encodePacked(
            hex"63",
            uint32(_code.length),
            hex"80_60_0E_60_00_39_60_00_F3",
            _code
        );
    }

    /**
      @notice Returns the size of the code on a given address
      @param _addr Address that may or may not contain code
      @return size of the code on the given `_addr`
    */
    function codeSize(address _addr) internal view returns (uint256 size) {
        assembly { size := extcodesize(_addr) }
    }

    /**
      @notice Returns the code of a given address
      @dev It will fail if `_end < _start`
      @param _addr Address that may or may not contain code
      @param _start number of bytes of code to skip on read
      @param _end index before which to end extraction
      @return oCode read from `_addr` deployed bytecode
      Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
    */
    function codeAt(address _addr, uint256 _start, uint256 _end) internal view returns (bytes memory oCode) {
        uint256 csize = codeSize(_addr);
        if (csize == 0) return bytes("");

        if (_start > csize) return bytes("");
        if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end);

    unchecked {
        uint256 reqSize = _end - _start;
        uint256 maxSize = csize - _start;

        uint256 size = maxSize < reqSize ? maxSize : reqSize;

        assembly {
        // allocate output byte array - this could also be done without assembly
        // by using o_code = new bytes(size)
            oCode := mload(0x40)
        // new "memory end" including padding
            mstore(0x40, add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        // store length in memory
            mstore(oCode, size)
        // actually retrieve the code, this needs assembly
            extcodecopy(_addr, add(oCode, 0x20), _start, size)
        }
    }
    }
}

//"SPDX-License-Identifier: BSD3
/**
 * Basic trigonometry functions
 *
 * Solidity library offering the functionality of basic trigonometry functions
 * with both input and output being integer approximated.
 *
 * This is useful since:
 * - At the moment no floating/fixed point math can happen in solidity
 * - Should be (?) cheaper than the actual operations using floating point
 *   if and when they are implemented.
 *
 * The implementation is based off Dave Dribin's trigint C library
 * http://www.dribin.org/dave/trigint/
 * Which in turn is based from a now deleted article which can be found in
 * the internet wayback machine:
 * http://web.archive.org/web/20120301144605/http://www.dattalo.com/technical/software/pic/picsine.html
 *
 * @author Lefteris Karapetsas
 * @license BSD3
 */
pragma solidity ^0.8.4;

library Trigonometry {

    // Table index into the trigonometric table
    uint constant INDEX_WIDTH = 4;
    // Interpolation between successive entries in the tables
    uint constant INTERP_WIDTH = 8;
    uint constant INDEX_OFFSET = 12 - INDEX_WIDTH;
    uint constant INTERP_OFFSET = INDEX_OFFSET - INTERP_WIDTH;
    uint16 constant ANGLES_IN_CYCLE = 16384;
    uint16 constant QUADRANT_HIGH_MASK = 8192;
    uint16 constant QUADRANT_LOW_MASK = 4096;
    uint constant SINE_TABLE_SIZE = 16;

    // constant sine lookup table generated by gen_tables.py
    // We have no other choice but this since constant arrays don't yet exist
    uint8 constant entry_bytes = 2;
    bytes constant sin_table = "\x00\x00\x0c\x8c\x18\xf9\x25\x28\x30\xfb\x3c\x56\x47\x1c\x51\x33\x5a\x82\x62\xf1\x6a\x6d\x70\xe2\x76\x41\x7a\x7c\x7d\x89\x7f\x61\x7f\xff";

    /**
     * Convenience function to apply a mask on an integer to extract a certain
     * number of bits. Using exponents since solidity still does not support
     * shifting.
     *
     * @param _value The integer whose bits we want to get
     * @param _width The width of the bits (in bits) we want to extract
     * @param _offset The offset of the bits (in bits) we want to extract
     * @return An integer containing _width bits of _value starting at the
     *         _offset bit
     */
    function bits(uint _value, uint _width, uint _offset) pure internal returns (uint) {
        return (_value / (2 ** _offset)) & (((2 ** _width)) - 1);
    }

    function sin_table_lookup(uint index) pure internal returns (uint16) {
        bytes memory table = sin_table;
        uint offset = (index + 1) * entry_bytes;
        uint16 trigint_value;
        assembly {
            trigint_value := mload(add(table, offset))
        }

        return trigint_value;
    }

    /**
     * Return the sine of an integer approximated angle as a signed 16-bit
     * integer.
     *
     * @param _angle A 14-bit angle. This divides the circle into 16384
     *               angle units, instead of the standard 360 degrees.
     * @return The sine result as a number in the range -32767 to 32767.
     */
    function sin(uint16 _angle) internal pure returns (int) {
        uint interp = bits(_angle, INTERP_WIDTH, INTERP_OFFSET);
        uint index = bits(_angle, INDEX_WIDTH, INDEX_OFFSET);

        bool is_odd_quadrant = (_angle & QUADRANT_LOW_MASK) == 0;
        bool is_negative_quadrant = (_angle & QUADRANT_HIGH_MASK) != 0;

        if (!is_odd_quadrant) {
            index = SINE_TABLE_SIZE - 1 - index;
        }

        uint x1 = sin_table_lookup(index);
        uint x2 = sin_table_lookup(index + 1);
        uint approximation = ((x2 - x1) * interp) / (2 ** INTERP_WIDTH);

        int sine;
        if (is_odd_quadrant) {
            sine = int(x1) + int(approximation);
        } else {
            sine = int(x2) - int(approximation);
        }

        if (is_negative_quadrant) {
            sine *= -1;
        }

        return sine;
    }

    /**
     * Return the cos of an integer approximated angle.
     * It functions just like the sin() method but uses the trigonometric
     * identity sin(x + pi/2) = cos(x) to quickly calculate the cos.
     */
    function cos(uint16 _angle) internal pure returns (int) {
        _angle = (_angle + QUADRANT_LOW_MASK) % ANGLES_IN_CYCLE;

        return sin(_angle);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Bytecode.sol";

/**
  @title A key-value storage with auto-generated keys for storing chunks of data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>
  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2 {
    error WriteError();

    /**
      @notice Stores `_data` and returns `pointer` as key for later retrieval
      @dev The pointer is a contract address with `_data` as code
      @param _data to be written
      @return pointer Pointer to the written `_data`
    */
    function write(bytes memory _data) internal returns (address pointer) {
        // Append 00 to _data so contract can't be called
        // Build init code
        bytes memory code = Bytecode.creationCodeFor(
            abi.encodePacked(
                hex'00',
                _data
            )
        );

        // Deploy contract using create
        assembly { pointer := create(0, add(code, 32), mload(code)) }

        // Address MUST be non-zero
        if (pointer == address(0)) revert WriteError();
    }

    /**
      @notice Reads the contents of the `_pointer` code as data, skips the first byte
      @dev The function is intended for reading pointers generated by `write`
      @param _pointer to be read
      @return data read from `_pointer` contract
    */
    function read(address _pointer) internal view returns (bytes memory) {
        return Bytecode.codeAt(_pointer, 1, type(uint256).max);
    }

    /**
      @notice Reads the contents of the `_pointer` code as data, skips the first byte
      @dev The function is intended for reading pointers generated by `write`
      @param _pointer to be read
      @param _start number of bytes to skip
      @return data read from `_pointer` contract
    */
    function read(address _pointer, uint256 _start) internal view returns (bytes memory) {
        return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
    }

    /**
      @notice Reads the contents of the `_pointer` code as data, skips the first byte
      @dev The function is intended for reading pointers generated by `write`
      @param _pointer to be read
      @param _start number of bytes to skip
      @param _end index before which to end extraction
      @return data read from `_pointer` contract
    */
    function read(address _pointer, uint256 _start, uint256 _end) internal view returns (bytes memory) {
        return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
    }
}

//"SPDX-License-Identifier: GPL-3.0

/*******************************************
              _                       _
             | |                     | |
  _ __   ___ | |_   _ ___   __ _ _ __| |_
 | '_ \ / _ \| | | | / __| / _` | '__| __|
 | |_) | (_) | | |_| \__ \| (_| | |  | |_
 | .__/ \___/|_|\__, |___(_)__,_|_|   \__|
 | |             __/ |
 |_|            |___/
 a homage to math, geometry and cryptography.
********************************************/

pragma solidity ^0.8.4;

import "./Trigonometry.sol";
import "./Fixed.sol";


library PolyRenderer {
    using Trigonometry for uint16;
    using Fixed for int64;

    struct Polygon {
        uint8 sides;
        uint8 color;
        uint64 size;
        uint16 rotation;
        uint64 top;
        uint64 left;
        uint64 opacity;
    }

    struct Circle {
        uint8 color;
        uint64 radius;
        uint64 c_y;
        uint64 c_x;
        uint64 opacity;
    }

    function svgOf(bytes calldata data, bool isCircle) external pure returns (string memory){
        // initialise svg
        string memory svg = '<svg width="256" height="256" viewBox="0 0 256 256" xmlns="http://www.w3.org/2000/svg">';

        // fill it with the background colour
        string memory bgColor = string(abi.encodePacked("rgb(", uint2str(uint8(data[0]), 0, 1), ",", uint2str(uint8(data[1]), 0, 1), ",", uint2str(uint8(data[2]), 0, 1), ")"));
        svg = string(abi.encodePacked(svg, '<rect width="256" height="256" fill="', bgColor, '"/>'));

        // load Palette
        string[4] memory colors;
        for (uint8 i = 0; i < 4; i++) {
            colors[i] = string(abi.encodePacked(uint2str(uint8(data[3 + i * 3]), 0, 1), ",", uint2str(uint8(data[4 + i * 3]), 0, 1), ",", uint2str(uint8(data[5 + i * 3]), 0, 1), ","));
        }

        // Fill it with Polygons or Circles
        uint polygons = (data.length - 15) / 5;
        string memory poly = '';
        Polygon memory polygon;
        for (uint i = 0; i < polygons; i++) {
            polygon = polygonFromBytes(data[15 + i * 5 : 15 + (i + 1) * 5]);
            poly = string(abi.encodePacked(poly,
                isCircle
                ? renderCircle(polygon, colors)
                : renderPolygon(polygon, colors))
            );
        }
        return string(abi.encodePacked(svg, poly, '</svg>'));
    }

    function attributesOf(bytes calldata data, bool isCircle) external pure returns (string memory){
        uint elements = (data.length - 15) / 5;
        if (isCircle) {
            return string(abi.encodePacked('[{"trait_type":"Circles","value":', uint2str(elements, 0, 1), '}]'));
        }
        string[4] memory types = ["Triangles", "Squares", "Pentagons", "Hexagons"];
        uint256[4] memory sides_count;
        for (uint i = 0; i < elements; i++) {
            sides_count[uint8(data[15 + i * 5] >> 6)]++;
        }
        string memory result = '[';
        string memory last;
        for (uint i = 0; i < 4; i++) {
            last = i == 3 ? '}' : '},';
            result = string(abi.encodePacked(result, '{"trait_type":"', types[i], '","value":',
                uint2str(sides_count[i], 0, 1), last));
        }
        return string(abi.encodePacked(result, ']'));
    }

    function renderCircle(Polygon memory polygon, string[4] memory colors) internal pure returns (string memory){
        int64 radius = getRadius(polygon.sides, polygon.size);
        return string(abi.encodePacked('<circle cx="', fixedToString(int64(polygon.left).toFixed(), 1), '" cy="',
            fixedToString(int64(polygon.top).toFixed(), 1), '" r="', fixedToString(radius, 1), '" style="fill:rgba(',
            colors[polygon.color], opacityToString(polygon.opacity), ')"/>'));
    }

    function opacityToString(uint64 opacity) internal pure returns (string memory) {
        return opacity == 31
        ? '1'
        : string(abi.encodePacked('0.', uint2str(uint64(int64(opacity).div(31).fractionPart()), 5, 1)));
    }

    function polygonFromBytes(bytes calldata data) internal pure returns (Polygon memory) {
        Polygon memory polygon;
        // read first two bits from the left and add 3
        polygon.sides = (uint8(data[0]) >> 6) + 3;
        // read the next two bits
        polygon.color = (uint8(data[0]) >> 4) & 3;
        // read the next 5 bits
        polygon.opacity = ((uint8(data[0]) % 16) << 1) + (uint8(data[1]) >> 7);
        // read the last 7 bits.
        polygon.rotation = uint8(data[1]) % 128;
        polygon.top = uint8(data[2]);
        polygon.left = uint8(data[3]);
        polygon.size = uint64(uint8(data[4])) + 1;
        return polygon;
    }

    function renderPolygon(Polygon memory polygon, string[4] memory colors) internal pure returns (string memory){
        int64[] memory points = getVertices(polygon);

        int64 v;
        int8 sign;
        string memory last;
        string memory result = '<polygon points="';
        for (uint j = 0; j < points.length; j++) {
            v = points[j];
            sign = v < 0 ? - 1 : int8(1);
            last = j == points.length - 1 ? '" style="fill:rgba(' : ",";
            result = string(abi.encodePacked(result, fixedToString(v, sign), last));
        }
        return string(abi.encodePacked(result, colors[polygon.color], opacityToString(polygon.opacity), ')"/>'));
    }

    function fixedToString(int64 fPoint, int8 sign) internal pure returns (bytes memory){
        return abi.encodePacked(uint2str(uint64(sign * fPoint.wholePart()), 0, sign), ".",
            uint2str(uint64(fPoint.fractionPart()), 5, 1));
    }

    function getRotationVector(uint16 angle) internal pure returns (int64[2] memory){
        // returns [cos(angle), -sin(angle)]
        return [
            int64(angle.cos()).div(32767), //-32767 to 32767.
            int64(-angle.sin()).div(32767)
        ];
    }

    function rotate(int64[2] memory R, int64[2] memory pos) internal pure returns (int64[2] memory){
        // R = [cos(angle), -sin(angle)]
        // rotation_matrix = [[cos(angle), -sin(angle)], [sin(angle), cos(angle)]]
        // this function returns rotation_matrix.dot(pos)
        int64[2] memory result;
        result[0] = R[0].mul(pos[0]) + R[1].mul(pos[1]);
        result[1] = - R[1].mul(pos[0]) + R[0].mul(pos[1]);
        return result;
    }

    function vectorSum(int64[2] memory a, int64[2] memory b) internal pure returns (int64[2] memory){
        return [a[0] + b[0], a[1] + b[1]];
    }

    function getRadius(uint8 sides, uint64 size) internal pure returns (int64){
        // the radius of the circumscribed circle is equal to the length of the regular poly edge divided by
        // cos(internal_angle/2).
        int64 cos_ang_2 = int64(uint64([7439101574, 6074001000, 5049036871, 4294967296][sides - 3]));
        return int64(size).toFixed().div(cos_ang_2);
    }

    function getVertices(Polygon memory polygon) internal pure returns (int64[] memory) {
        int64[] memory result = new int64[](2 * polygon.sides);
        uint16 internalAngle = [1365, 2048, 2458, 2731][polygon.sides - 3]; // Note: 16384 is 2pi
        uint16 angle = [5461, 4096, 3277, 2731][polygon.sides - 3]; // 16384/sides
        int64 radius = getRadius(polygon.sides, polygon.size);

        // We map our rotation that goes from [0, 128[, to [0, 16384/sides[. 16384 is 2pi on the Trigonometry package.
        // We say 128 = 16384/sides because if you rotate a regular polygon by 2pi/number_of_sides it will be exactly the
        // same as rotating it by 2pi (due to the symmetries of regular polys).
        // We gain more precision by taking advantage of these symmetries.

        uint16 rotation = uint16((polygon.rotation << 7) / polygon.sides + internalAngle);

        int64[2] memory R = getRotationVector(rotation);
        int64[2] memory vector = rotate(R, [radius, 0]);
        int64[2] memory center = [int64(polygon.left).toFixed(), int64(polygon.top).toFixed()];
        int64[2] memory pos = vectorSum(center, vector);
        result[0] = pos[0];
        result[1] = pos[1];
        R = getRotationVector(angle);
        for (uint8 i = 0; i < polygon.sides - 1; i++) {
            vector = rotate(R, vector);
            pos = vectorSum(center, vector);
            result[(i + 1) * 2] = pos[0];
            result[(i + 1) * 2 + 1] = pos[1];
        }
        return result;
    }

    function uint2str(uint _i, uint8 zero_padding, int8 sign) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        if ((zero_padding > 0) && (zero_padding > length)) {
            uint pad_length = zero_padding - length;
            bytes memory pad = new bytes(pad_length);
            k = 0;
            while (k < pad_length) {
                pad[k++] = bytes1(uint8(48));
            }
            bstr = abi.encodePacked(pad, bstr);
        }
        if (sign < 0) {
            return string(abi.encodePacked("-", bstr));
        } else {
            return string(bstr);
        }
    }
}

// SPDX-License-Identifier: MIT
/*******************************************
              _                       _
             | |                     | |
  _ __   ___ | |_   _ ___   __ _ _ __| |_
 | '_ \ / _ \| | | | / __| / _` | '__| __|
 | |_) | (_) | | |_| \__ \| (_| | |  | |_
 | .__/ \___/|_|\__, |___(_)__,_|_|   \__|
 | |             __/ |
 |_|            |___/

 a homage to math, geometry and cryptography.
********************************************/
pragma solidity ^0.8.4;


library Fixed {
    uint8 constant scale = 32;

    function toFixed(int64 i) internal pure returns (int64){
        return i << scale;
    }

    function toInt(int64 f) internal pure returns (int64){
        return f >> scale;
    }

    /// @notice outputs the first 5 decimal places
    function fractionPart(int64 f) internal pure returns (int64){
        int8 sign = f < 0 ? - 1 : int8(1);
        // zero out the digits before the comma
        int64 fraction = (sign * f) & 2 ** 32 - 1;
        // Get the first 5 decimals
        return int64(int128(fraction) * 1e5 >> scale);
    }

    function wholePart(int64 f) internal pure returns (int64){
        return f >> scale;
    }

    function mul(int64 a, int64 b) internal pure returns (int64) {
        return int64(int128(a) * int128(b) >> scale);
    }

    function div(int64 a, int64 b) internal pure returns (int64){
        return int64((int128(a) << scale) / b);
    }
}

pragma solidity ^0.8.4;

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

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

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
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
        return _owners[tokenId] != address(0);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    constructor() {
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
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