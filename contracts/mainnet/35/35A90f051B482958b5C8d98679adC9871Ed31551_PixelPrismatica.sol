// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

import "./pixel_prismatica_utils.sol";
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

    // Helper Contracts
    PixelPrismaticaUtils private constant UTILS = PixelPrismaticaUtils(0x44E0DA58B239D218164E3746E6b02372785A4413);

    // Chain information.
    uint256 private constant CHAIN_ID = 1;
    uint256 private constant CHAIN_INITIAL_MINT_FEE = 0.025 ether;
    string private constant CHAIN_NAME = "Ethereum";

    // The number of different colors each tile cycles through. This is chosen experimentally so that the NFT will display in most sites.
    uint256 private constant NUM_COLORS = 5;

    // The max number of NFT mints available per network.
    uint256 private constant MAX_MINTS = 100;

    // Set in CTOR, but cannot be marked as immutable
    mapping(uint256 => string) private map_animationDuration2AnimationDurationString;
    mapping(uint256 => uint256) private map_animationDuration2AnimationDurationValue;
    mapping(uint256 => string) private map_colorMode2ColorModeString;
    mapping(uint256 => bytes4) private map_colorMode2ColorModeValue;
    mapping(uint256 => string) private map_imageSize2ImageSizeString;
    mapping(uint256 => uint256) private map_imageSize2ImageSizeValue;

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
        string animationDurationString;
        uint256 animationDurationValue;

        string colorModeString;
        bytes4 colorModeValue;

        string imageSizeString;
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

    mapping(uint256 => NFTConfig) private map_id2NFTConfig;
    mapping(uint256 => address) private map_id2NFTOwnerAddress;

    mapping(address => mapping(address => bool)) private map_address2OperatorAddress2IsApproved;
    mapping(uint256 => mapping(address => uint256)) private map_id2Address2Balance;

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
        assert(block.chainid == CHAIN_ID);

        // Set the initial mint fee. This will increase automatically as more NFTs are minted.
        setMintFee(CHAIN_INITIAL_MINT_FEE);

        // Defaults are set here, but these can be changed manually after the contract is deployed.
        setRoyaltyAddress(address(this));
        setRoyaltyBasisPoints(300);

        setStoreName(string.concat("Pixel Prismatica NFT Collection (", CHAIN_NAME, ")"));
        setStoreDescription("A collection of configurable NFT tokens featuring animated pixel art, capped at 100 per network. https://musicslayer.github.io/pixel_prismatica_dapp/");
        setStoreImageURI("https://raw.githubusercontent.com/musicslayer/pixel_prismatica_dapp/main/store_image.png");
        setStoreExternalLinkURI("https://musicslayer.github.io/pixel_prismatica_dapp/");

        // Store the data for all possible configuration options.
        map_animationDuration2AnimationDurationString[0] = "Short Animation Duration";
        map_animationDuration2AnimationDurationString[1] = "Medium Animation Duration";
        map_animationDuration2AnimationDurationString[2] = "Long Animation Duration";
        map_animationDuration2AnimationDurationString[3] = "No Animation";
        map_animationDuration2AnimationDurationValue[0] = 4;
        map_animationDuration2AnimationDurationValue[1] = 10;
        map_animationDuration2AnimationDurationValue[2] = 20;
        map_animationDuration2AnimationDurationValue[3] = 0;

        map_colorMode2ColorModeString[0] = "Rainbow Light Color Mode";
        map_colorMode2ColorModeString[1] = "Rainbow Dark Color Mode";
        map_colorMode2ColorModeString[2] = "Monochrome Color Mode";
        map_colorMode2ColorModeString[3] = "Red Color Mode";
        map_colorMode2ColorModeString[4] = "Green Color Mode";
        map_colorMode2ColorModeString[5] = "Blue Color Mode";
        map_colorMode2ColorModeString[6] = "Green & Blue Color Mode";
        map_colorMode2ColorModeString[7] = "Red & Green Color Mode";
        map_colorMode2ColorModeString[8] = "Red & Blue Color Mode";
        map_colorMode2ColorModeString[9] = "Cyan Color Mode";
        map_colorMode2ColorModeString[10] = "Yellow Color Mode";
        map_colorMode2ColorModeString[11] = "Magenta Color Mode";
        map_colorMode2ColorModeValue[0] = UTILS.getRainbowLightColorString.selector;
        map_colorMode2ColorModeValue[1] = UTILS.getRainbowDarkColorString.selector;
        map_colorMode2ColorModeValue[2] = UTILS.getMonochromeColorString.selector;
        map_colorMode2ColorModeValue[3] = UTILS.getRedColorString.selector;
        map_colorMode2ColorModeValue[4] = UTILS.getGreenColorString.selector;
        map_colorMode2ColorModeValue[5] = UTILS.getBlueColorString.selector;
        map_colorMode2ColorModeValue[6] = UTILS.getGreenBlueColorString.selector;
        map_colorMode2ColorModeValue[7] = UTILS.getRedGreenColorString.selector;
        map_colorMode2ColorModeValue[8] = UTILS.getRedBlueColorString.selector;
        map_colorMode2ColorModeValue[9] = UTILS.getCyanColorString.selector;
        map_colorMode2ColorModeValue[10] = UTILS.getYellowColorString.selector;
        map_colorMode2ColorModeValue[11] = UTILS.getMagentaColorString.selector;

        map_imageSize2ImageSizeString[0] = "Small Image Size";
        map_imageSize2ImageSizeString[1] = "Medium Image Size";
        map_imageSize2ImageSizeString[2] = "Large Image Size";
        map_imageSize2ImageSizeValue[0] = 10;
        map_imageSize2ImageSizeValue[1] = 18;
        map_imageSize2ImageSizeValue[2] = 24;
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

    function applyConfig(uint256 _id, uint256 _colorMode, uint256 _animationDuration, uint256 _imageSize) private {
        setColorMode(_id, _colorMode);
        setAnimationDuration(_id, _animationDuration);
        setImageSize(_id, _imageSize);
    }

    function mint(address _address, uint256 _colorMode, uint256 _animationDuration, uint256 _imageSize, bytes memory _data) private {
        // This NFT is always minted one at a time.
        require(_address != address(0), "ERC1155: mint to the zero address");

        currentID++;

        map_id2Address2Balance[currentID][_address] = 1;
        setNFTOwner(currentID, _address);

        // Fill in NFTConfig struct.
        map_id2NFTConfig[currentID] = NFTConfig("", 0, "", 0, "", 0, 0, 0, 0);
        applyConfig(currentID, _colorMode, _animationDuration, _imageSize);

        // Every time an NFT is minted, increase the minting cost for the next one.
        uint256 newMintFee = getMintFee();
        newMintFee = (newMintFee * 105) / 100;
        newMintFee = (newMintFee / 0.0001 ether) * 0.0001 ether; // Truncate extra decimal places.
        setMintFee(newMintFee);
        
        emit Mint(currentID, _address);
        emit TransferSingle(msg.sender, address(0), _address, currentID, 1);

        _doSafeTransferAcceptanceCheck(msg.sender, address(0), _address, currentID, 1, _data);
    }

    /*
        Helper Functions
    */

    function createDescription(uint256 _id) private view returns (string memory) {
        if(_id == 0 || _id > currentID) {
            return "(Unminted)";
        }
        else {
            string memory colorModeString = map_id2NFTConfig[_id].colorModeString;
            string memory animationDurationString = map_id2NFTConfig[_id].animationDurationString;
            string memory imageSizeString = map_id2NFTConfig[_id].imageSizeString;
            return string.concat("Configuration: ", colorModeString, " - ", animationDurationString, " - ", imageSizeString);
        }
    }

    function createImageURI(uint256 _id) private view returns (string memory) {
        if(_id == 0 || _id > currentID) {
            return "";
        }

        uint256[2] memory RND;
        RND[0] = UTILS.getInitialSeed();
        RND[1] = _id + (CHAIN_ID * 1000);

        NFTConfig memory nftConfig = map_id2NFTConfig[_id];

        bytes4 selector = nftConfig.colorModeValue;
        uint256 width = nftConfig.rectWidth * nftConfig.numRectX;
        uint256 height = nftConfig.rectHeight * nftConfig.numRectY;
        string memory animationDurationString = string.concat(uint256ToStringFast(nftConfig.animationDurationValue), "s");

        uint256 i = 0;
        slice[] memory content = new slice[](14 + nftConfig.numRectX * nftConfig.numRectY * (13 + 2 * (NUM_COLORS - 1)));

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
                string memory first;
                (first, RND) = UTILS.getColorString(selector, RND);

                content[i++] = slice_toSlice("<use href=\"#b\" x=\"");
                content[i++] = slice_toSlice(uint256ToStringFast(rectX));
                content[i++] = slice_toSlice("\" y=\"");
                content[i++] = slice_toSlice(uint256ToStringFast(rectY));
                content[i++] = slice_toSlice("\" fill=\"");
                content[i++] = slice_toSlice(first);
                content[i++] = slice_toSlice("\"><animate attributeName=\"fill\" values=\"");

                content[i++] = slice_toSlice(first);
                content[i++] = slice_toSlice(";");
                for(uint256 ii = 0; ii < NUM_COLORS - 1; ii++) {
                    string memory colorString;
                    (colorString, RND) = UTILS.getColorString(selector, RND);
                    content[i++] = slice_toSlice(colorString);
                    content[i++] = slice_toSlice(";");
                }
                content[i++] = slice_toSlice(first);

                content[i++] = slice_toSlice("\" dur=\"");
                content[i++] = slice_toSlice(animationDurationString);
                content[i++] = slice_toSlice("\" repeatCount=\"indefinite\"/></use>");
            }
        }

        content[i++] = slice_toSlice("</svg>");

        string memory contentString = slice_join(slice_toSlice(""), content);
        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(abi.encodePacked(contentString))));
    }

    function createName(uint256 _id) private pure returns (string memory) {
        return string.concat("Pixel Prismatica NFT #", uint256ToString(_id));
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

    function getDescription(uint256 _id) private view returns (string memory) {
        return createDescription(_id);
    }

    function getImageURI(uint256 _id) private view returns (string memory) {
        return createImageURI(_id);
    }

    function getMintFee() private view returns (uint256) {
        return mintFee;
    }

    function getName(uint256 _id) private pure returns (string memory) {
        return createName(_id);
    }

    function getNFTOwner(uint256 _id) private view returns (address) {
        return map_id2NFTOwnerAddress[_id];
    }

    function getOpenSeaData() private view returns (string memory) {
        return contractURI();
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

    function getTotalMints() private view returns (uint256) {
        return currentID;
    }

    /*
        Set Functions
    */

    function setAnimationDuration(uint256 _id, uint256 _animationDuration) private {
        if(_animationDuration > 3) {
            _animationDuration = 1; // Default to Medium
        }
        map_id2NFTConfig[_id].animationDurationString = map_animationDuration2AnimationDurationString[_animationDuration];
        map_id2NFTConfig[_id].animationDurationValue = map_animationDuration2AnimationDurationValue[_animationDuration];
    }

    function setColorMode(uint256 _id, uint256 _colorMode) private {
        if(_colorMode > 11) {
            _colorMode = 0; // Default to Rainbow Light
        }
        map_id2NFTConfig[_id].colorModeString = map_colorMode2ColorModeString[_colorMode];
        map_id2NFTConfig[_id].colorModeValue = map_colorMode2ColorModeValue[_colorMode];
    }

    function setImageSize(uint256 _id, uint256 _imageSize) private {
        if(_imageSize > 2) {
            _imageSize = 1; // Default to Medium
        }
        map_id2NFTConfig[_id].imageSizeString = map_imageSize2ImageSizeString[_imageSize];

        // These are all the same value but are kept separate to make the code more understandable.
        uint256 imageSizeValue = map_imageSize2ImageSizeValue[_imageSize];
        map_id2NFTConfig[_id].numRectX = imageSizeValue;
        map_id2NFTConfig[_id].numRectY = imageSizeValue;
        map_id2NFTConfig[_id].rectWidth = imageSizeValue;
        map_id2NFTConfig[_id].rectHeight = imageSizeValue;
    }

    function setMintFee(uint256 _mintFee) private {
        mintFee = _mintFee;
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
    /// @param _animationDuration The new animation duration.
    /// @param _imageSize The new image size.
    function action_applyConfig(uint256 _id, uint256 _colorMode, uint256 _animationDuration, uint256 _imageSize) external {
        lock();

        requireNFTOwner(_id, msg.sender);

        applyConfig(_id, _colorMode, _animationDuration, _imageSize);

        unlock();
    }

    /// @notice A user can mint an NFT.
    /// @param _colorMode The initial color mode.
    /// @param _animationDuration The initial animation duration.
    /// @param _imageSize The initial image size.
    /// @param _data Additional data with no specified format.
    function action_mint(uint256 _colorMode, uint256 _animationDuration, uint256 _imageSize, bytes memory _data) external payable {
        lock();

        requireRemainingMints();
        requireMintFee(msg.value);

        mint(msg.sender, _colorMode, _animationDuration, _imageSize, _data);

        unlock();
    }

    /// @notice The owner can trigger a mint for someone else.
    /// @param _address The address that the owner is triggering the mint for.
    /// @param _colorMode The initial color mode.
    /// @param _animationDuration The initial animation duration.
    /// @param _imageSize The initial image size.
    /// @param _data Additional data with no specified format.
    function action_mintOther(address _address, uint256 _colorMode, uint256 _animationDuration, uint256 _imageSize, bytes memory _data) external payable {
        lock();

        requireOwnerAddress(msg.sender);
        requireRemainingMints();
        requireMintFee(msg.value);
        
        mint(_address, _colorMode, _animationDuration, _imageSize, _data);

        unlock();
    }

    /*
        Query Functions
    */

    /// @notice Returns whether the amount is equal to the current mint fee.
    /// @return Whether the amount is equal to the current mint fee.
    function query_isMintFee(uint256 _value) external view returns (bool) {
        return isMintFee(_value);
    }

    /// @notice Returns whether the address owns the NFT.
    /// @param _id The ID of the NFT.
    /// @param _address The address that we are checking.
    /// @return Whether the address owns the NFT.
    function query_isNFTOwner(uint256 _id, address _address) external view returns (bool) {
        return isNFTOwner(_id, _address);
    }

    /// @notice Returns whether there are any remaining NFT mints available.
    /// @return Whether there are any remaining NFT mints available.
    function query_isRemainingMints() external view returns (bool) {
        return isRemainingMints();
    }

    /*
        Get Functions
    */

    /// @notice Returns the description of the NFT.
    /// @param _id The ID of the NFT.
    /// @return The description of the NFT.
    function get_description(uint256 _id) external view returns (string memory) {
        return getDescription(_id);
    }

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

    /// @notice Returns the name of the NFT.
    /// @param _id The ID of the NFT.
    /// @return The name of the NFT.
    function get_name(uint256 _id) external pure returns (string memory) {
        return getName(_id);
    }

    /// @notice Returns the address that owns the NFT.
    /// @param _id The ID of the NFT.
    /// @return The address that owns the NFT.
    function get_nftOwner(uint256 _id) external view returns (address) {
        return getNFTOwner(_id);
    }

    /// @notice Returns the OpenSea data.
    /// @return The OpenSea data.
    function get_openSeaData() external view returns (string memory) {
        return getOpenSeaData();
    }

    /// @notice Returns the number of remaining NFT mints available.
    /// @return The number of remaining NFT mints available.
    function get_remainingMints() external view returns (uint256) {
        return getRemainingMints();
    }

    /// @notice Returns the address that royalties will be paid to.
    /// @return The address that royalties will be paid to.
    function get_royaltyAddress() external view returns (address) {
        return getRoyaltyAddress();
    }

    /// @notice Returns the royalty basis points.
    /// @return The royalty basis points.
    function get_royaltyBasisPoints() external view returns (uint256) {
        return getRoyaltyBasisPoints();
    }

    /// @notice Returns the total number of NFTs that have been minted.
    /// @return The total number of NFTs that have been minted.
    function get_totalMints() external view returns (uint256) {
        return getTotalMints();
    }

    /*
        Set Functions
    */

    /// @notice The owner can set the address that royalties will be paid to.
    /// @param _royaltyAddress The new address that royalties will be paid to.
    function set_royaltyAddress(address _royaltyAddress) external {
        lock();

        requireOwnerAddress(msg.sender);

        setRoyaltyAddress(_royaltyAddress);

        unlock();
    }

    /// @notice The owner can set the royalty basis points.
    /// @param _royaltyBasisPoints The new royalty basis points.
    function set_royaltyBasisPoints(uint256 _royaltyBasisPoints) external {
        lock();

        requireOwnerAddress(msg.sender);

        setRoyaltyBasisPoints(_royaltyBasisPoints);

        unlock();
    }

    /// @notice The owner can set the store description.
    /// @param _storeDescription The new store description.
    function set_storeDescription(string memory _storeDescription) external {
        lock();

        requireOwnerAddress(msg.sender);

        setStoreDescription(_storeDescription);

        unlock();
    }

    /// @notice The owner can set the store external link URI.
    /// @param _storeExternalLinkURI The new store external link URI.
    function set_storeExternalLinkURI(string memory _storeExternalLinkURI) external {
        lock();

        requireOwnerAddress(msg.sender);

        setStoreExternalLinkURI(_storeExternalLinkURI);

        unlock();
    }

    /// @notice The owner can set the store image URI.
    /// @param _storeImageURI The new store image URI.
    function set_storeImageURI(string memory _storeImageURI) external {
        lock();

        requireOwnerAddress(msg.sender);

        setStoreImageURI(_storeImageURI);

        unlock();
    }

    /// @notice The owner can set the store name.
    /// @param _storeName The new store name.
    function set_storeName(string memory _storeName) external {
        lock();

        requireOwnerAddress(msg.sender);

        setStoreName(_storeName);

        unlock();
    }
}