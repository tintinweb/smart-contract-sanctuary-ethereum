// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

//import "github.com/musicslayer/standard_contract/contracts/standard_contract.sol";
import "./standard_contract.sol";

// import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
interface IERC1155MetadataURI is IERC1155 {
    function uri(uint256 id) external view returns (string memory);
}

// import "@openzeppelin/contracts/interfaces/IERC2981.sol";
interface IERC2981 is IERC165 {
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);
}

contract PixelPrismatica is StandardContract, IERC1155MetadataURI, IERC2981 {
    /*
    *
    *
        Errors
    *
    *
    */

    /// @notice The required minting fee has not been paid.
    error MintFeeError(uint256 value, uint256 mintFee);

    /// @notice There are no remaining NFT mints available.
    error NoRemainingMintsError();

    /// @notice The address does not own the NFT.
    error NotNFTOwnerError(uint256 id, address _address, address nftOwner);

    /*
    *
    *
        Events
    *
    *
    */

    /// @notice A record of an NFT being minted.
    event Mint(uint256 indexed id, address indexed mintAddress);

    /*
    *
    *
        Constants
    *
    *
    */

    // The identifier and name of the chain that this contract is meant to be deployed on.
    uint256 private constant CHAIN_ID = 97;
    string private constant CHAIN_NAME = "Binance Smart Chain (Testnet)";

    // The number of different colors each tile cycles through. This is chosen experimentally so that the NFT will display in most sites.
    uint256 private constant NUM_COLORS = 5;

    // The max number of NFT mints available.
    uint256 private constant MAX_MINTS = 100;

    /*
    *
    *
        Private Variables
    *
    *
    */

    /*
        NFT Variables
    */
    struct NFTConfig { 
        uint256 colorMode;
        uint256 duration;
        uint256 numColors;
        uint256 numRectX;
        uint256 numRectY;
        uint256 rectWidth;
        uint256 rectHeight;
    }

    uint256 private currentID;
    
    uint256 private mintFee;
    address private royaltyAddress;
    uint256 private royaltyBasisPoints;
    
    string private storeDescription;
    string private storeExternalLinkURI;
    string private storeImageURI;
    string private storeName;

    mapping(uint256 => string) private map_id2ColorModeString;
    mapping(uint256 => string) private map_id2DurationString;
    mapping(uint256 => string) private map_id2SizeString;

    mapping(uint256 => NFTConfig) private map_id2NFTConfig;

    mapping(address => mapping(address => bool)) private map_address2OperatorAddress2IsApproved;
    mapping(uint256 => mapping(address => uint256)) private map_id2Address2Balance;
    mapping(uint256 => address) private map_id2NFTOwnerAddress;

    /*
        RNG Variables
    */

    uint256 private constant multiplier = 0x5DEECE66D;
    uint256 private constant addend = 0xB;
    uint256 private constant mask = (1 << 48) - 1;
    uint256 private immutable rnd0;
    uint256 private rnd;

    /*
    *
    *
        Contract Functions
    *
    *
    */

    /*
        Built-In Functions
    */

    constructor() StandardContract() payable {
        //assert(block.chainid == CHAIN_ID);

        // Initialize RNG seed.
        rnd0 = ((uint256(blockhash(block.number - 1))) ^ multiplier) & mask;

        // Set the initial mint fee. This will increase automatically as more NFTs are minted.
        //setMintFee(0.1 ether);
        //setMintFee(0.0 ether);
        setMintFee(0.01 ether);

        // The royalty is fixed at 3%
        setRoyaltyBasisPoints(300);

        // Defaults are set here, but these can be changed manually after the contract is deployed.
        setRoyaltyAddress(address(this));
        setStoreName(string.concat("Pixel Prismatica NFT Collection (", CHAIN_NAME, ")"));
        setStoreDescription("A collection of 100 configurable NFT tokens featuring colorful pixel art. https://musicslayer.github.io/pixel_prismatica_dapp/");
        setStoreImageURI("https://raw.githubusercontent.com/musicslayer/pixel_prismatica_dapp/main/store_image.png");
        setStoreExternalLinkURI("https://musicslayer.github.io/pixel_prismatica_dapp/");
    }

    fallback() external payable {
        // There is no legitimate reason for this fallback function to be called.
        punish();
    }

    receive() external payable {}

    /*
        Implementation Functions
    */

    // IERC165 Implementation
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, StandardContract) returns (bool) {
        return interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IERC1155).interfaceId
            || interfaceId == type(IERC1155MetadataURI).interfaceId 
            || interfaceId == type(IERC2981).interfaceId
            || super.supportsInterface(interfaceId);
    }

    // IERC1155 Implementation
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return map_id2Address2Balance[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) public view virtual override returns (uint256[] memory) {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for(uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(msg.sender != operator, "ERC1155: setting approval status for self");

        map_address2OperatorAddress2IsApproved[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return map_address2OperatorAddress2IsApproved[account][operator];
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual override {
        requireNotPaused();
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(from == msg.sender || isApprovedForAll(from, msg.sender), "ERC1155: caller is not token owner or approved");

        uint256 fromBalance = map_id2Address2Balance[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");

        map_id2Address2Balance[id][from] = fromBalance - amount;
        map_id2Address2Balance[id][to] += amount;

        // For this token, the amount is always 1 per id, so we can keep track of the owner directly.
        setNFTOwner(id, to);

        emit TransferSingle(msg.sender, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(msg.sender, from, to, id, amount, data);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual override {
        requireNotPaused();
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(from == msg.sender || isApprovedForAll(from, msg.sender), "ERC1155: caller is not token owner or approved");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        for(uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = map_id2Address2Balance[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");

            map_id2Address2Balance[id][from] = fromBalance - amount;
            map_id2Address2Balance[id][to] += amount;

            // For this token, the amount is always 1 per id, so we can keep track of the owner directly.
            setNFTOwner(id, to);
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, ids, amounts, data);
    }

    function _doSafeTransferAcceptanceCheck(address operator, address from, address to, uint256 id, uint256 amount, bytes memory data) private {
        if(to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if(response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            }
            catch Error(string memory reason) {
                revert(reason);
            }
            catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) private {
        if(to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if(response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            }
            catch Error(string memory reason) {
                revert(reason);
            }
            catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    // IERC1155MetadataURI Implementation
    function uri(uint256 id) external view returns (string memory) {
        // The JSON data is directly encoded here.
        string memory name = createName(id);
        string memory description = createDescription(id);
        string memory imageURI = createImageURI(id);

        string memory uriString = string.concat('{"name":"', name, '", "description":"', description, '", "image":"', imageURI, '"}');
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(abi.encodePacked(uriString))));
    }

    // IERC2981 Implementation
    function royaltyInfo(uint256, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        receiver = royaltyAddress;
        royaltyAmount = (salePrice * royaltyBasisPoints) / 10000;
    }

    // OpenSea Standard
    function contractURI() public view returns (string memory) {
        // The JSON data is directly encoded here.
        string memory uriString = string.concat('{"name":"', storeName, '", "description":"', storeDescription, '", "image":"', storeImageURI, '", "external_link":"', storeExternalLinkURI, '", "seller_fee_basis_points":', uint256ToString(royaltyBasisPoints), ', "fee_recipient":"', addressToString(royaltyAddress), '"}');
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(abi.encodePacked(uriString))));
    }

    /*
        Action Functions
    */

    function applyConfig(uint256 _id, uint256 _colorMode, uint256 _duration, uint256 _imageSize) private {
        setColorMode(_id, _colorMode);
        setNumColors(_id, NUM_COLORS); // The user cannot change this.
        setDuration(_id, _duration);
        setImageSize(_id, _imageSize);
    }

    function mint(address _address, uint256 _colorMode, uint256 _duration, uint256 _imageSize, bytes memory _data) private {
        // This NFT is always minted one at a time.
        requireNotPaused();
        require(_address != address(0), "ERC1155: mint to the zero address");

        currentID++;

        map_id2Address2Balance[currentID][_address] = 1;
        setNFTOwner(currentID, _address);

        // Fill in NFTConfig struct.
        map_id2NFTConfig[currentID] = NFTConfig(0, 0, 0, 0, 0, 0, 0);
        applyConfig(currentID, _colorMode, _duration, _imageSize);

        // Every time an NFT is minted, increase the minting cost for the next one.
        setMintFee((getMintFee() * 105) / 100);
        
        emit Mint(currentID, _address);
        emit TransferSingle(msg.sender, address(0), _address, currentID, 1);

        _doSafeTransferAcceptanceCheck(msg.sender, address(0), _address, currentID, 1, _data);
    }

    /*
        Helper Functions
    */

    function createName(uint256 _id) public pure returns (string memory) {
        return string.concat("Pixel Prismatica NFT #", uint256ToString(_id));
    }

    function createDescription(uint256 _id) public view returns (string memory) {
        if(_id == 0 || _id > currentID) {
            return "(Unminted)";
        }
        else {
            return string.concat("Configuration: ", map_id2ColorModeString[_id], " - ", map_id2DurationString[_id], " - ", map_id2SizeString[_id]);
        }
    }

    function createImageURI(uint256 _id) private view returns (string memory) {
        if(_id == 0 || _id > currentID) {
            return "";
        }

        uint256[2] memory RND;
        RND[0] = rnd0;
        RND[1] = _id;

        NFTConfig memory nftConfig = map_id2NFTConfig[_id];

        uint256 width = nftConfig.rectWidth * nftConfig.numRectX;
        uint256 height = nftConfig.rectHeight * nftConfig.numRectY;
        string memory durationString = string.concat(uint256ToStringFast(nftConfig.duration), "s");

        uint256 i = 0;
        slice[] memory content = new slice[](14 + nftConfig.numRectX * nftConfig.numRectY * (13 + 2 * (nftConfig.numColors - 1)));

        content[i++] = slice_toSlice("<?xml version=\"1.1\"?>");
        content[i++] = slice_toSlice("<svg width=\"");
        content[i++] = slice_toSlice(uint256ToStringFast(width));
        content[i++] = slice_toSlice("\" height=\"");
        content[i++] = slice_toSlice(uint256ToStringFast(height));
        content[i++] = slice_toSlice("\" xmlns=\"http://www.w3.org/2000/svg\">");
        content[i++] = slice_toSlice("<defs>");
        content[i++] = slice_toSlice("<rect id=\"b\" width=\"");
        content[i++] = slice_toSlice(uint256ToStringFast(nftConfig.rectWidth));
        content[i++] = slice_toSlice("\" height=\"");
        content[i++] = slice_toSlice(uint256ToStringFast(nftConfig.rectHeight));
        content[i++] = slice_toSlice("\"/>");
        content[i++] = slice_toSlice("</defs>");
        
        for(uint256 rectY = 0; rectY < height; rectY += nftConfig.rectHeight) {
            for(uint256 rectX = 0; rectX < width; rectX += nftConfig.rectWidth) {
                string memory first = getColorString(RND, nftConfig.colorMode);

                content[i++] = slice_toSlice("<use href=\"#b\" x=\"");
                content[i++] = slice_toSlice(uint256ToStringFast(rectX));
                content[i++] = slice_toSlice("\" y=\"");
                content[i++] = slice_toSlice(uint256ToStringFast(rectY));
                content[i++] = slice_toSlice("\" fill=\"");
                content[i++] = slice_toSlice(first);
                content[i++] = slice_toSlice("\"><animate attributeName=\"fill\" values=\"");

                content[i++] = slice_toSlice(first);
                content[i++] = slice_toSlice(";");
                for(uint256 ii = 0; ii < nftConfig.numColors - 1; ii++) {
                    content[i++] = slice_toSlice(getColorString(RND, nftConfig.colorMode));
                    content[i++] = slice_toSlice(";");
                }
                content[i++] = slice_toSlice(first);

                content[i++] = slice_toSlice("\" dur=\"");
                content[i++] = slice_toSlice(durationString);
                content[i++] = slice_toSlice("\" repeatCount=\"indefinite\"/></use>");
            }
        }

        content[i++] = slice_toSlice("</svg>");

        string memory contentString = slice_join(slice_toSlice(""), content);
        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(abi.encodePacked(contentString))));
    }

    /*
        Query Functions
    */

    function isMintFee(uint256 _value) private view returns (bool) {
        return _value == getMintFee();
    }

    function isNFTOwner(uint256 _id, address _address) private view returns (bool) {
        return _address == getNFTOwner(_id);
    }

    function isRemainingMints() private view returns (bool) {
        return getRemainingMints() != 0;
    }

    /*
        Require Functions
    */

    function requireMintFee(uint256 _value) private view {
        if(!isMintFee(_value)) {
            revert MintFeeError(_value, getMintFee());
        }
    }

    function requireNFTOwner(uint256 _id, address _address) private view {
        if(!isNFTOwner(_id, _address)) {
            revert NotNFTOwnerError(_id, _address, getNFTOwner(_id));
        }
    }

    function requireRemainingMints() private view {
        if(!isRemainingMints()) {
            revert NoRemainingMintsError();
        }
    }

    /*
        Get Functions
    */

    function getImageURI(uint256 _id) private view returns (string memory) {
        return createImageURI(_id);
    }

    function getMintFee() private view returns (uint256) {
        return mintFee;
    }

    function getNFTOwner(uint256 _id) private view returns (address) {
        return map_id2NFTOwnerAddress[_id];
    }

    function getRemainingMints() private view returns (uint256) {
        return MAX_MINTS - currentID;
    }

    function getRoyaltyAddress() private view returns (address) {
        return royaltyAddress;
    }

    function getRoyaltyBasisPoints() private view returns (uint256) {
        return royaltyBasisPoints;
    }

    function getStoreDescription() private view returns (string memory) {
        return storeDescription;
    }

    function getStoreExternalLinkURI() private view returns (string memory) {
        return storeExternalLinkURI;
    }

    function getStoreImageURI() private view returns (string memory) {
        return storeImageURI;
    }

    function getStoreName() private view returns (string memory) {
        return storeName;
    }

    function getTotalMints() private view returns (uint256) {
        return currentID;
    }

    /*
        Set Functions
    */

    function setColorMode(uint256 _id, uint256 _colorMode) private {
        if(_colorMode > 11) {
            _colorMode = 0;
        }
        map_id2NFTConfig[_id].colorMode = _colorMode;
        map_id2ColorModeString[_id] = "X Color Mode";

        /*
        if(_colorMode == 0) {
            map_id2ColorModeString[_id] = "Rainbow Light Color Mode";
        }
        else if(_colorMode == 1) {
            map_id2ColorModeString[_id] = "Rainbow Dark Color Mode";
        }
        else if(_colorMode == 2) {
            map_id2ColorModeString[_id] = "Monochrome Color Mode";
        }
        else if(_colorMode == 3) {
            map_id2ColorModeString[_id] = "Red Color Mode";
        }
        else if(_colorMode == 4) {
            map_id2ColorModeString[_id] = "Green Color Mode";
        }
        else if(_colorMode == 5) {
            map_id2ColorModeString[_id] = "Blue Color Mode";
        }
        else if(_colorMode == 6) {
            map_id2ColorModeString[_id] = "Green & Blue Color Mode";
        }
        else if(_colorMode == 7) {
            map_id2ColorModeString[_id] = "Red & Green Color Mode";
        }
        else if(_colorMode == 8) {
            map_id2ColorModeString[_id] = "Red & Blue Color Mode";
        }
        else if(_colorMode == 9) {
            map_id2ColorModeString[_id] = "Cyan Color Mode";
        }
        else if(_colorMode == 10) {
            map_id2ColorModeString[_id] = "Yellow Color Mode";
        }
        else if(_colorMode == 11) {
            map_id2ColorModeString[_id] = "Magenta Color Mode";
        }
        */
    }

    function setDuration(uint256 _id, uint256 _duration) private {
        if(_duration == 0) {
            map_id2DurationString[currentID] = "Short Animation Duration";
            map_id2NFTConfig[_id].duration = 4;
        }
        else if(_duration == 1) {
            map_id2DurationString[currentID] = "Medium Animation Duration";
            map_id2NFTConfig[_id].duration = 10;
        }
        else {
            map_id2DurationString[currentID] = "Long Animation Duration";
            map_id2NFTConfig[_id].duration = 20;
        }
    }

    function setImageSize(uint256 _id, uint256 _imageSize) private {
        if(_imageSize == 0) {
            map_id2SizeString[currentID] = "Small Image Size";
            map_id2NFTConfig[_id].numRectX = 10;
            map_id2NFTConfig[_id].numRectY = 10;
            map_id2NFTConfig[_id].rectWidth = 10;
            map_id2NFTConfig[_id].rectHeight = 10;
        }
        else if(_imageSize == 1) {
            map_id2SizeString[currentID] = "Medium Image Size";
            map_id2NFTConfig[_id].numRectX = 18;
            map_id2NFTConfig[_id].numRectY = 18;
            map_id2NFTConfig[_id].rectWidth = 18;
            map_id2NFTConfig[_id].rectHeight = 18;
        }
        else {
            map_id2SizeString[currentID] = "Large Image Size";
            map_id2NFTConfig[_id].numRectX = 24;
            map_id2NFTConfig[_id].numRectY = 24;
            map_id2NFTConfig[_id].rectWidth = 24;
            map_id2NFTConfig[_id].rectHeight = 24;
        }
    }

    function setMintFee(uint256 _mintFee) private {
        mintFee = _mintFee;
    }

    function setNumColors(uint256 _id, uint256 _numColors) private {
        map_id2NFTConfig[_id].numColors = _numColors;
    }

    function setNFTOwner(uint256 _id, address _address) private {
        map_id2NFTOwnerAddress[_id] = _address;
    }

    function setRoyaltyAddress(address _royaltyAddress) private {
        royaltyAddress = _royaltyAddress;
    }

    function setRoyaltyBasisPoints(uint256 _royaltyBasisPoints) private {
        royaltyBasisPoints = _royaltyBasisPoints;
    }

    function setStoreDescription(string memory _storeDescription) private {
        storeDescription = _storeDescription;
    }

    function setStoreExternalLinkURI(string memory _storeExternalLinkURI) private {
        storeExternalLinkURI = _storeExternalLinkURI;
    }

    function setStoreImageURI(string memory _storeImageURI) private {
        storeImageURI = _storeImageURI;
    }

    function setStoreName(string memory _storeName) private {
        storeName = _storeName;
    }

    /*
        Utility Functions
    */

    bytes16 private constant HEX_SYMBOLS = "0123456789ABCDEF";
    function get3Hex(uint256 valueA, uint256 valueB, uint256 valueC) internal pure returns (string memory) {
        // Each value must be < 256.
        bytes memory buffer = new bytes(7);
        buffer[0] = "#";
        buffer[1] = HEX_SYMBOLS[(valueA & 0xf0) >> 4];
        buffer[2] = HEX_SYMBOLS[valueA & 0xf];
        buffer[3] = HEX_SYMBOLS[(valueB & 0xf0) >> 4];
        buffer[4] = HEX_SYMBOLS[valueB & 0xf];
        buffer[5] = HEX_SYMBOLS[(valueC & 0xf0) >> 4];
        buffer[6] = HEX_SYMBOLS[valueC & 0xf];

        return string(buffer);
    }

    bytes16 private constant DECIMAL_SYMBOLS = "0123456789";
    function uint256ToStringFast(uint256 _i) internal pure returns (string memory) {
        // Only works for values < 1000
        bytes memory buffer;
        if(_i < 10) {
            buffer = new bytes(1);
            buffer[0] = DECIMAL_SYMBOLS[_i];
        }
        else if(_i < 100) {
            buffer = new bytes(2);
            buffer[0] = DECIMAL_SYMBOLS[_i / 10];
            buffer[1] = DECIMAL_SYMBOLS[_i % 10];
        }
        else {
            buffer = new bytes(3);
            buffer[0] = DECIMAL_SYMBOLS[(_i / 10) / 10];
            buffer[1] = DECIMAL_SYMBOLS[(_i / 10) % 10];
            buffer[2] = DECIMAL_SYMBOLS[_i % 10];
        }

        return string(buffer);
    }

    /*
        RNG Functions
    */

    function nextInt(uint256[2] memory RND, uint256 n) private pure returns (uint256) {
        // Return a random integer.
        // Only call if n is not a power of 2.
        RND[0] = (RND[0] * multiplier + addend + RND[1]) & mask;
        return (RND[0] >> 17) % n;
    }

    function nextInt2P(uint256[2] memory RND, uint256 n) private pure returns (uint256) {
        // Return a random integer.
        // Only call if n is a power of 2.
        RND[0] = (RND[0] * multiplier + addend + RND[1]) & mask;
        return (n * (RND[0] >> 17)) >> 31;
    }

    /*
        String Slice Functions
        Taken from @Arachnid/src/strings.sol
    */
    struct slice {
        uint _len;
        uint _ptr;
    }

    function slice_memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint _mask = type(uint).max;
        if (len > 0) {
            _mask = 256 ** (32 - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(_mask))
            let destpart := and(mload(dest), _mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    function slice_toSlice(string memory self) private pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    function slice_join(slice memory self, slice[] memory parts) private pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint i = 0; i < parts.length; i++) {
            slice_memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                slice_memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }

    /*
        Color Functions
    */

    function getColorString(uint256[2] memory RND, uint256 _colorMode) private pure returns (string memory) {
        if(_colorMode == 0) {
            return getRainbowLightColorString(RND);
        }
        else if(_colorMode == 1) {
            return getRainbowDarkColorString(RND);
        }
        else if(_colorMode == 2) {
            return getMonochromeColorString(RND);
        }
        else if(_colorMode == 3) {
            return getRedColorString(RND);
        }
        else if(_colorMode == 4) {
            return getGreenColorString(RND);
        }
        else if(_colorMode == 5) {
            return getBlueColorString(RND);
        }
        else if(_colorMode == 6) {
            return getGreenBlueColorString(RND);
        }
        else if(_colorMode == 7) {
            return getRedGreenColorString(RND);
        }
        else if(_colorMode == 8) {
            return getRedBlueColorString(RND);
        }
        else if(_colorMode == 9) {
            return getCyanColorString(RND);
        }
        else if(_colorMode == 10) {
            return getYellowColorString(RND);
        }
        else if(_colorMode == 11) {
            return getMagentaColorString(RND);
        }
        else {
            // Default to Rainbow Light
            return getRainbowLightColorString(RND);
        }
    }

    function getRainbowLightColorString(uint256[2] memory RND) internal pure returns (string memory) {
        uint256 c = 255;
        uint256 r = nextInt(RND, 6);

        string memory s;
        if(r == 0) {
            s = get3Hex(c, 0, 0);
        }
        else if(r == 1) {
            s = get3Hex(0, c, 0);
        }
        else if(r == 2) {
            s = get3Hex(0, 0, c);
        }
        else if(r == 3) {
            s = get3Hex(0, c, c);
        }
        else if(r == 4) {
            s = get3Hex(c, c, 0);
        }
        else if(r == 5) {
            s = get3Hex(c, 0, c);
        }
        else {
            s = "?";
        }

        return s;
    }

    function getRainbowDarkColorString(uint256[2] memory RND) private pure returns (string memory) {
        uint256 c = 128;
        uint256 r = nextInt(RND, 6);

        string memory s;
        if(r == 0) {
            s = get3Hex(c, 0, 0);
        }
        else if(r == 1) {
            s = get3Hex(0, c, 0);
        }
        else if(r == 2) {
            s = get3Hex(0, 0, c);
        }
        else if(r == 3) {
            s = get3Hex(0, c, c);
        }
        else if(r == 4) {
            s = get3Hex(c, c, 0);
        }
        else if(r == 5) {
            s = get3Hex(c, 0, c);
        }
        else {
            s = "?";
        }

        return s;
    }

    function getMonochromeColorString(uint256[2] memory RND) private pure returns (string memory) {
        uint256 c = nextInt2P(RND, 256);
        return get3Hex(c, c, c);
    }

    function getRedColorString(uint256[2] memory RND) private pure returns (string memory) {
        uint256 c = nextInt2P(RND, 256);
        return get3Hex(c, 0, 0);
    }

    function getGreenColorString(uint256[2] memory RND) private pure returns (string memory) {
        uint256 c = nextInt2P(RND, 256);
        return get3Hex(0, c, 0);
    }

    function getBlueColorString(uint256[2] memory RND) private pure returns (string memory) {
        uint256 c = nextInt2P(RND, 256);
        return get3Hex(0, 0, c);
    }

    function getGreenBlueColorString(uint256[2] memory RND) private pure returns (string memory) {
        uint256 cA = nextInt2P(RND, 256);
        uint256 cB = nextInt2P(RND, 256);
        return get3Hex(0, cA, cB);
    }

    function getRedGreenColorString(uint256[2] memory RND) private pure returns (string memory) {
        uint256 cA = nextInt2P(RND, 256);
        uint256 cB = nextInt2P(RND, 256);
        return get3Hex(cA, cB, 0);
    }

    function getRedBlueColorString(uint256[2] memory RND) private pure returns (string memory) {
        uint256 cA = nextInt2P(RND, 256);
        uint256 cB = nextInt2P(RND, 256);
        return get3Hex(cA, 0, cB);
    }

    function getCyanColorString(uint256[2] memory RND) private pure returns (string memory) {
        uint256 c = nextInt2P(RND, 256);
        return get3Hex(0, c, c);
    }

    function getYellowColorString(uint256[2] memory RND) private pure returns (string memory) {
        uint256 c = nextInt2P(RND, 256);
        return get3Hex(c, c, 0);
    }

    function getMagentaColorString(uint256[2] memory RND) private pure returns (string memory) {
        uint256 c = nextInt2P(RND, 256);
        return get3Hex(c, 0, c);
    }

    /*
    *
    *
        External Functions
    *
    *
    */

    /*
        Action Functions
    */

    /// @notice The NFT owner can configure their NFT.
    /// @param _id The ID of the NFT.
    /// @param _colorMode The new color mode.
    /// @param _duration The new animation duration.
    /// @param _imageSize The new image size.
    function action_applyConfig(uint256 _id, uint256 _colorMode, uint256 _duration, uint256 _imageSize) external {
        lock();

        requireNFTOwner(_id, msg.sender);

        applyConfig(_id, _colorMode, _duration, _imageSize);

        unlock();
    }

    /// @notice A user can mint an NFT for a token address.
    /// @param _colorMode The initial color mode.
    /// @param _duration The initial animation duration.
    /// @param _imageSize The initial image size.
    /// @param _data Additional data with no specified format.
    function action_mint(uint256 _colorMode, uint256 _duration, uint256 _imageSize, bytes memory _data) external payable {
        lock();

        requireRemainingMints();
        requireMintFee(msg.value);

        mint(msg.sender, _colorMode, _duration, _imageSize, _data);

        unlock();
    }

    /// @notice The operator can trigger a mint for someone else.
    /// @param _address The address that the operator is triggering the mint for.
    /// @param _colorMode The initial color mode.
    /// @param _duration The initial animation duration.
    /// @param _imageSize The initial image size.
    /// @param _data Additional data with no specified format.
    function action_mintOther(address _address, uint256 _colorMode, uint256 _duration, uint256 _imageSize, bytes memory _data) external payable {
        lock();

        requireOperatorAddress(msg.sender);
        requireRemainingMints();
        requireMintFee(msg.value);
        
        mint(_address, _colorMode, _duration, _imageSize, _data);

        unlock();
    }

    /*
        Query Functions
    */

    /// @notice Returns whether there are any remaining NFT mints available.
    /// @return Whether there are any remaining NFT mints available.
    function query_isRemainingMints() external view returns (bool) {
        return isRemainingMints();
    }

    /// @notice Returns whether the address owns the NFT.
    /// @param _id The ID of the NFT.
    /// @param _address The address that we are checking.
    /// @return Whether the address owns the NFT.
    function query_isNFTOwner(uint256 _id, address _address) external view returns (bool) {
        return isNFTOwner(_id, _address);
    }

    /*
        Get Functions
    */

    /// @notice Returns the image URI of the NFT.
    /// @param _id The ID of the NFT.
    /// @return The image URI of the NFT.
    function get_imageURI(uint256 _id) external view returns (string memory) {
        return getImageURI(_id);
    }

    /// @notice Returns the mint fee.
    /// @return The mint fee.
    function get_mintFee() external view returns (uint256) {
        return getMintFee();
    }

    /// @notice Returns the address that owns the NFT.
    /// @param _id The ID of the NFT.
    /// @return The address that owns the NFT.
    function get_nftOwner(uint256 _id) external view returns (address) {
        return getNFTOwner(_id);
    }

    /// @notice Returns the number of remaining NFT mints available.
    /// @return The number of remaining NFT mints available.
    function get_remainingMints() external view returns (uint256) {
        return getRemainingMints();
    }

    /// @notice Returns the total number of NFTs that have been minted.
    /// @return The total number of NFTs that have been minted.
    function get_totalMints() external view returns (uint256) {
        return getTotalMints();
    }

    /*
        Set Functions
    */

    /// @notice The NFT owner can set the color mode of the NFT.
    /// @param _id The ID of the NFT.
    /// @param _colorMode The new color mode.
    function set_colorMode(uint256 _id, uint256 _colorMode) external {
        lock();

        requireNFTOwner(_id, msg.sender);

        setColorMode(_id, _colorMode);

        unlock();
    }

    /// @notice The NFT owner can set the animation duration of the NFT.
    /// @param _id The ID of the NFT.
    /// @param _duration The new animation duration in seconds.
    function set_duration(uint256 _id, uint256 _duration) external {
        lock();

        requireNFTOwner(_id, msg.sender);

        setDuration(_id, _duration);

        unlock();
    }

    /// @notice The NFT owner can set the image size of the NFT.
    /// @param _id The ID of the NFT.
    /// @param _imageSize The new image size.
    function set_imageSize(uint256 _id, uint256 _imageSize) external {
        lock();

        requireNFTOwner(_id, msg.sender);

        setImageSize(_id, _imageSize);

        unlock();
    }
}