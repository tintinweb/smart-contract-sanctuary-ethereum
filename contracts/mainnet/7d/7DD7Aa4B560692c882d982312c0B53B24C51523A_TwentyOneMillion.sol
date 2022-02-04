// SPDX-License-Identifier: UNKNOWN
// For licensing contact [email protected]

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./BaseConversion.sol";

/**
 * @title 21MMpixels
 * 21MMpixels - The self describing token representing your piece of blockchain history.
 * 
 * Each purchased token represents 2500 pixels within the 21 million pixel image.  
 * 
 * The original 21MMpixels website is available at https://21mmpixels.com
 *
 * There are 8400 original issue 50x50 pixel tokens.  Token IDS 1-8400 represent these
 * original tiles.  The location of each tile is immutable, find out the location of any
 * tile within the 6000 pixel x 3500 pixel grid for as long as Ethereum exists with 
 * the tileDescription view function.  
 *
 * Collect and merge 4 adjacent tokens to make a single 10,000 pixel big token.  Merging
 * tokens will burn the original tiles, and issue a single big token with a token ID 
 * of the original top left token + 10000.
 *
 * If you're a real big shot, collect and merge 4 big tokens to create a 40,000 pixel
 * super token.  The four big Token IDs will be burned and a single super token with
 * a token ID of the original top left token + 20000. 
 * 
 * You can set the image for your token once token redemption begins.  To determine the 
 * cost of altering the image for your token, call the imageManipulationPrice 
 * view function.  The price is set to 1/21 * the tile price for each 2500 pixels 
 * represented by a token, not to exceed 0.02 ether per 2500 pixels.  Once the sale has 
 * concluded, anyone can activate redemption if the  contract owner has not yet 
 * activated redemption.   
 * 
 * Set the image for your tile in 61 bytes of storage space, with Solidity based 
 * support for storing and displaying IPFS CIDv1 file links and Arweave Transaction 
 * IDs.  Storing your image is simple: call the cidv1ToBytes view function with
 * your IPFS image cidV1, or call the arweaveTxIdToBytes view function with your
 * Arweave tx id to get all the data needed to store your image record.
 *
 * Set a URL for your token to link to for the price of the gas, retrievable with 
 * a view function by anyone.  
 *
 * Change the image and URL for your tile anytime redemption is active, and update 
 * the 21MM Pixel image in real time.  
 *
 * Make your record permanent by calling the lock token function, which prevents any 
 * future changes to your token and its image.  
 */

contract TwentyOneMillion is ERC721Tradable, IERC2981, BaseConversion {

    
    constructor(address _proxyRegistryAddress) ERC721Tradable("21MM Pixels", "PIXL", _proxyRegistryAddress) {
        
    }

    struct RedeemedStruct{
        uint8 redeemedAndLocked;  
        bytes1 multibase;  
        /* UTF-8 encoding of mutlibase: 
            0x62 = b - rfc4648 case-insensitive - no padding (IPFS cidV1)
            0x01 = Arweave tx id
            0x75 = Base64URL   */     
        bytes30 digest1;
        uint16 size;   // Number of bytes in digests to use
        bytes30 digest2;
    }

    bool    private _active;
    bool    private _salePaused;
    bool public redeemable;
    uint private _maxMint;            
    uint private _maxMintTotal;  
    uint private _price;
    // solhint-disable-next-line
    uint public constant royalty = 500;
    uint public constant TILE_LIMIT = 8400;
    uint private constant _MAX_REDEMPTION_PRICE = 20_000_000_000_000_000;
    string private _baseTokenURI;
    string private _contractURI;
    

    mapping (uint256 => string) private _tokenIdToUrl;
    mapping (uint256 => RedeemedStruct) private _tokenIdToRedeemed;
    
    event TokenImageSet(uint indexed tokenId, address indexed currentOwner, bytes30 digest1, bytes30 digest2, bytes1 multibase, uint16 size, bool locked);
    event TokensMerged(uint256 upperLeft, uint256 upperRight, uint256 lowerLeft, uint256 lowerRight, uint256 indexed newToken, bool merged);
    event TokenUrlSet(uint indexed tokenId, string url);

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
    /**
     * Read-only function to show details about the project.
     */ 
 
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        require(_exists(_tokenId), "Token does not exist");
        return string(abi.encodePacked(_baseURI(), Strings.toString(_tokenId)));
    }

    /**
     * Read-only function to show the stored image link.
     */
    function tokenImg(uint256 tokenId) public view returns (string memory ipfsLink, bytes30 digest1, bytes30 digest2, bytes1 multibase, uint16 size){
        require(_exists(tokenId), "Token does not exist");
        RedeemedStruct storage redeemed = _tokenIdToRedeemed[tokenId];
        require(redeemed.redeemedAndLocked != 0, "No image set");
        if (redeemed.multibase == 0x62 || redeemed.multibase == 0x42){
            string memory link = byteArraysToBase32String(redeemed.digest1, redeemed.digest2, redeemed.multibase, redeemed.size);
            return (string(abi.encodePacked("ipfs://", link)), redeemed.digest1, redeemed.digest2, redeemed.multibase, redeemed.size); 
        }
        else if (redeemed.multibase == 0x75){
            string memory link = byteArraysToBase64String(redeemed.digest1, redeemed.digest2, redeemed.size);
            return(string(abi.encodePacked(link)), redeemed.digest1, redeemed.digest2, redeemed.multibase, redeemed.size); 
        }
        else if (redeemed.multibase == 0x01){
            string memory link = byteArraysToBase64String(redeemed.digest1, redeemed.digest2, redeemed.size);
            return(string(abi.encodePacked("arweave://",link)), redeemed.digest1, redeemed.digest2, redeemed.multibase, redeemed.size); 
        }
        else{
            return ("", redeemed.digest1, redeemed.digest2, redeemed.multibase, redeemed.size);
        }
    }

    /**
     * Read-only function to show any URL associated with a token (tile).
     */

     function tokenLinkUrl(uint256 tokenId) public view returns (string memory url){
         require(_exists(tokenId), "Token does not exist");
         RedeemedStruct memory redeemed = _tokenIdToRedeemed[tokenId];
         require(redeemed.redeemedAndLocked > 0, "Tile not set");
         return _tokenIdToUrl[tokenId];
     }

    /**
     * Read-only function to show if a token has been permanently locked.  Once a token is
     * locked, the image can not be modified, and the tile represented by that token can not
     * be merged or unmerged.
     */
    function tokenLocked(uint256 tokenId) public view returns (bool){
        require(_exists(tokenId), "Token does not exist");
        return (_tokenIdToRedeemed[tokenId].redeemedAndLocked == 2);
    }

    /**
     * Read-only function to determine if sale is active.  
     */
    function active() external view returns(bool) {
        return _active;
    }

    /**
     * Read-only function to retrieve the current price to mint a single 50x50 tiles.
     */
    function pricePerTile() public view returns (uint256) {
        require(_active, "Not active");
        return _price;
    }

    /**
     * Read-only function to retrieve maximum mint total.
     */
    function maxMintTotal() public view returns (uint256) {
        require(_active, "Not active");
        return _maxMintTotal;
    }

    /**
     * Read-only function to retrieve maximum mint per transaction.
     */
    function maxMintPerTransaction() public view returns (uint256) {
        require(_active, "Not active");
        return _maxMint;
    }

    /**
     * Read-only function to calculate the data to store a cidv1 base32 IPFS pointer for an image file.  
     * Provided for convenience.
     */
    function cidv1ToBytes(string memory _cidv1) public pure returns (bytes30 digest1, bytes30 digest2, bytes1 multibase, uint16 length) {
        bytes memory bytesArray =  bytes(_cidv1);
        uint8 firstByte = uint8(bytesArray[0]);
        require(firstByte == 98, "Not rfc4648");
        (digest1, digest2, multibase, length) = base32stringToBytes(_cidv1);
        return (digest1, digest2, multibase, length);
    }

    /**
     * Read-only function to calculate the data to store an Arweave tx id for an image file.  
     * Provided for convenience.
     */
    function arweaveTxIdToBytes(string memory _txid) public pure returns (bytes30 digest1, bytes30 digest2, bytes1 multibase, uint16 length) {
        (digest1, digest2, multibase, length) = base64URLstringToBytes(_txid);
        return (digest1, digest2, 0x01, length);
    }

    /**
     * Read-only function to calculate the data to store Base64URL encoded links for an image file.  
     * Provided for convenience.
     */
    function base64URLToBytes(string memory _url) public pure returns (bytes30 digest1, bytes30 digest2, bytes1 multibase, uint16 length) {
        (digest1, digest2, multibase, length) = base64URLstringToBytes(_url);
        return (digest1, digest2, 0x01, length);
    }

    /** 
     * Read-only function to show the price to merge four 50x50 or four 100x100 tiles.
     */
    function mergePrice(uint tokenId) public view returns (uint256){
        require(_exists(tokenId), "Token does not exist");
        require(tokenId > 0, "Invalid token");
        require(tokenId < 20000, "Too large to merge");
        if (tokenId > 10000){
            return _price * 4;
        }
        else{
            return _price * 2;
        }
    }

    /**
     * Read-only function to show current price to set or unset the image for a tile.
     */
    function imageManipulationPrice(uint tokenId) public view returns (uint256){
        require(_exists(tokenId), "Token does not exist");
        uint size = tokenId / 10000;
        uint price = _price;

        return ((price / 21) > _MAX_REDEMPTION_PRICE ? _MAX_REDEMPTION_PRICE : (price / 21)) * (4 ** size); 
    }

    /**
     * Read-only function to show the coordinates, dimensions, and size of a tile.  Does not check if tile exists.
     */
     function tileDescription(uint256 tokenId) public pure returns (string memory){
        (uint x, uint y, uint dimensions) = tileDescriptionArray(tokenId);
        string memory xCoord = Strings.toString(x);
        string memory yCoord = Strings.toString(y);
        string memory pixels = Strings.toString(dimensions * dimensions);
        string memory sizeS = Strings.toString(dimensions) ;
        return string(abi.encodePacked("x: ",xCoord, " y: ", yCoord, " size: ",sizeS, "x", sizeS, " pixels: ", pixels));
     }


    function tileDescriptionArray(uint256 tokenId) public pure returns (uint x, uint y, uint dimension){
        uint tempId = tokenId - 1;
        uint size = 0;
        uint column = 0;
        uint row = 0;
        if (tokenId > 10000){
            size = tempId / 10000;
            tempId = tempId - 10000 * size;
        }

        if (tempId == 0){
            // It's 0:0
        }
        else if (tempId < 2485) {       
            uint ind = 0;
            uint bigger = 0;

            while(bigger < tempId){
                ind++;
                bigger = bigger + ind; 
            }

            if (bigger == tempId){
                row = ind;
            }
            else{
                column = tempId + ind - bigger;
                row = bigger - tempId - 1;
            }
        }
        else if (tempId < 5985){
            uint ind = (tempId - 2485) / 70;
            uint bigger = 2485 + ind * 70;

            if (bigger == tempId){
                column = ind + 1;
                row = 69;
            }
            else{ 
                column = tempId - bigger + ind + 1;
                row = bigger + 69 - tempId;
            }
        }
        else if (tempId < 8400){
            uint ind = 0;
            uint bigger = 5985;

            while(bigger < tempId){
                ind++;
                bigger = bigger + (70 - ind); 
            }

            if (bigger == tempId){
                column = ind + 51;
                row = 69;
            }
            else{
                column = 120 + tempId - bigger;
                row = bigger + ind - tempId - 1;
            }
        }
        else {
            revert("Invalid tile");
        }

        x = column * 50;
        y = row * 50;
        dimension = 50 + (size * size) * 25 + size * 25;
        require((x + dimension) < 6001 && (y + dimension) < 3501, "Invalid tile");
    }

    /** 
     * Read-only function to retrieve the tiles that are adjacent to a tile 
     */
    function showAdjacentTiles(uint256 _topLeftTile) public pure returns (uint right, uint below, uint diag) {
        require(_topLeftTile < 20000, "Invalid tile");
        uint tempId = _topLeftTile;
        uint mergeType = 0;

        if (tempId > 10000){
                mergeType = 1;
                tempId = tempId - 10000;
        }

        (right, below, diag) = _adjacentTiles(tempId, mergeType);
    }

    /**
     * Read-only function to retrieve the total number of NFTs that have been minted thus far
     */
    function getTotalMinted() external view returns (uint256) {
        return totalSupply();
    }

    /**
     * Read-only function to retrieve the total number of NFTs that remain to be minted
     */
    function getTotalRemainingCount() external view returns (uint256) {
        return (TILE_LIMIT - totalSupply());
    }

// Royalty info
    function royaltyInfo (
            // solhint-disable-next-line no-unused-vars
            uint256 _tokenId,
            uint256 _salePrice
        ) external view override(IERC2981) returns (
            address receiver,
            uint256 royaltyAmount
        ) {
            // Royalty payment is 5% of the sale price
            uint256 royaltyPmt = _salePrice*royalty/10000;
            require(royaltyPmt > 0, "Royalty must be greater than 0");
            require(_exists(_tokenId), "Token does not exist");
            return (address(this), royaltyPmt);
        }

// Callable functions 
    function mint(uint64 _tiles) external payable callerIsUser {
        require(_active && !_salePaused, "Inactive");
        require(_tiles >= 1 && _tiles <= _maxMint, "Invalid quantity");
        require(_tiles + totalSupply() <= TILE_LIMIT,"Sold out");
        require(_tiles + balanceOf(msg.sender) <= _maxMintTotal, "Too many owned");
        require(msg.value == _tiles * _price, "Invalid amount sent"); 
        for (uint i = 0; i < _tiles; i++){
            _mintTo(msg.sender); 
        }
    }

    /**
     * Merges four adjactent tiles into a single larger tile.  Can be used on four 50x50 or
     * four 100x100 tiles.  Call function with the upper left tile Token ID.  Burns the four
     * merged tiles and issues a new tile.  Cost to merge tiles can be found with the mergePrice
     * view function.
    */
    function mergeTiles(uint256 _topLeftTile) external payable callerIsUser {
        require(_topLeftTile < 20000, "Too large to merge");
        require(ERC721.ownerOf(_topLeftTile) == msg.sender, "Top left token not owned");
        require(msg.value == mergePrice(_topLeftTile), "Invalid amount sent");
        uint tempId = _topLeftTile;
        uint mergeType = 0;

        if (_topLeftTile > 10000){
                mergeType = 1;
                tempId = tempId - 10000;
        }

        (uint right, uint bottom, uint diag) = _adjacentTiles(tempId, mergeType);
        
        require(ERC721.ownerOf(right) == msg.sender, "Top right token not owned");
        require(ERC721.ownerOf(bottom) == msg.sender, "Lower left token not owned");
        require(ERC721.ownerOf(diag) == msg.sender, "Lower right token not owned");

        require(_tokenIdToRedeemed[_topLeftTile].redeemedAndLocked != 2, "Top left token locked");
        require(_tokenIdToRedeemed[right].redeemedAndLocked != 2, "Top right token locked");
        require(_tokenIdToRedeemed[bottom].redeemedAndLocked != 2, "Bottom left token locked");
        require(_tokenIdToRedeemed[diag].redeemedAndLocked != 2, "Bottom right token locked");

        delete _tokenIdToRedeemed[_topLeftTile];
        delete _tokenIdToRedeemed[right];
        delete _tokenIdToRedeemed[bottom];
        delete _tokenIdToRedeemed[diag];

        delete _tokenIdToUrl[_topLeftTile];
        delete _tokenIdToUrl[right];
        delete _tokenIdToUrl[bottom];
        delete _tokenIdToUrl[diag];
        
        emit TokenImageSet(_topLeftTile, msg.sender, 0x0, 0x0, "", 0, false);
        emit TokenImageSet(right, msg.sender, 0x0, 0x0, "", 0, false);
        emit TokenImageSet(bottom, msg.sender, 0x0, 0x0, "", 0, false);
        emit TokenImageSet(diag, msg.sender, 0x0, 0x0, "", 0, false);
        emit TokenUrlSet(_topLeftTile, "");
        emit TokenUrlSet(right, "");
        emit TokenUrlSet(bottom, "");
        emit TokenUrlSet(diag, "");

        _burn(_topLeftTile);
        _burn(right);
        _burn(bottom);
        _burn(diag);

        uint bigTokenId = 10000 + _topLeftTile;
        _safeMint(msg.sender, bigTokenId);
        emit TokensMerged(_topLeftTile, right, bottom, diag, bigTokenId, true);
    }

    /**
     * Function to unmerge a 100x100 tile into four 50x50 tiles, or a 200x200 tile into four
     * 100x100 tiles.  Burns the larger tile, and mints four smaller tiles to owner.
    */
    function unmergeTiles(uint256 _tile) external callerIsUser {
        require(_tile > 10000, "Can not split single tile");
        require(ERC721.ownerOf(_tile) == msg.sender, "Token not owned");
        require(_tokenIdToRedeemed[_tile].redeemedAndLocked != 2, "Token locked");

        uint tempId = _tile - 10000;
        uint mergeType = 0;

        if (tempId > 10000){
                mergeType = 1;
                tempId = tempId - 10000;
        }

        (uint right, uint bottom, uint diag) = _adjacentTiles(tempId, mergeType);

        uint newLeft = _tile - 10000;

        delete _tokenIdToRedeemed[_tile];
        delete _tokenIdToUrl[_tile];
        //emit TokenImageUnset(_tile, msg.sender);  
        emit TokenImageSet(_tile, msg.sender, 0x0, 0x0, "", 0, false);      
        emit TokenUrlSet(_tile, "");

        _burn(_tile);
        _safeMint(msg.sender, newLeft);
        _safeMint(msg.sender, right);
        _safeMint(msg.sender, bottom);
        _safeMint(msg.sender, diag);

        emit TokensMerged(newLeft, right, bottom, diag, _tile, false);
    }

    /**
     *  Internal function to determine adjacent tiles given a top left tile.
    */
    function _adjacentTiles(uint256 _topLeftTile, uint256 _mergeType) internal pure returns (uint right,uint bottom,uint diag) {
        require(_topLeftTile < 8399, "Invalid starting tile");
        require(_topLeftTile > 0, "Invalid starting tile");
        uint tempId = _topLeftTile - 1;

        if (tempId < 2346) {       
            uint ind = 34;
            uint upper = 70;
            uint lower = 0;
            uint bigger = 595;
            
                while(!(tempId < bigger && tempId >= (bigger - ind))){
                    if (tempId >= bigger){
                        lower = ind;
                        ind = (ind + upper) / 2;
                        bigger = (ind * (ind + 1)) / 2;                 
                    }
                    else { 
                        upper = ind;
                        ind = ((ind + lower) / 2);
                        bigger = (ind * (ind + 1)) / 2;                     
                    }
                }

            if (_mergeType == 0){
                right = _topLeftTile + ind + 1;
                bottom = _topLeftTile + ind;
                diag = _topLeftTile + 2 * ind + 2;
            }
            else {
                require(_topLeftTile != 2279, "Invalid starting tile");
                
                right = _topLeftTile + ind + ind + 3;
                bottom = _topLeftTile + ind + ind + 1;
                diag = _topLeftTile + 4 * ind + 8;
                if (_topLeftTile > 2211){
                    diag = diag - (2 * ind - 133);
                }
            }
        }
        else if (tempId < 5915){
            uint testLower = (tempId - 2345) % 70;
            if (_mergeType == 0){
                require(testLower != 0, "Invalid starting tile");
                right = _topLeftTile + 70;
                bottom = _topLeftTile + 69;
                diag = _topLeftTile + 139; 
            }
            else{
                require(testLower > 2 && tempId < 5913 && tempId != 5844, "Invalid starting tile");  
                bottom = _topLeftTile + 138;
                right = _topLeftTile + 140;
                diag = _topLeftTile + 278;
                if (tempId > 5776  && tempId < 5847){
                    diag -= 1;
                }
                else if (tempId > 5846){
                    diag = diag - 3;
                }
            }
        }
        else  {   
            uint ind = 35;
            uint upper = 70;
            uint lower = 0;
            uint bigger = 7770;
            
                while(!(tempId <= bigger && tempId > (bigger - (71 - ind)))){
                    if (tempId > bigger){
                        lower = ind;
                        ind = (ind + upper) / 2;
                        bigger = 8400 - ((71 - ind) * (70 - ind)) / 2;
                    }
                    else {
                        upper = ind;
                        ind = (ind + lower) / 2;  
                        bigger = 8400 - ((71 - ind) * (70 - ind)) / 2;
                    }
                }

            require(tempId != bigger, "Invalid starting tile");

            uint256 testRight = (bigger - 1) - tempId;

            if (_mergeType == 0){         
                require(testRight != 0, "Invalid starting tile");
                right = _topLeftTile + (71 - ind);
                bottom = _topLeftTile + (70 - ind);
                diag = _topLeftTile + 138 - ((ind - 1) * 2);
            }
            else {
                require(testRight > 2, "Invalid starting tile");
                uint testBottom = tempId - (bigger - (71 - ind));
                require(testBottom > 2, "Invalid starting tile");
                right = _topLeftTile + (141 - ind * 2);
                bottom = _topLeftTile + (139 - ind * 2);
                diag = _topLeftTile + 272 - ((ind - 1) * 4);
            }
        }

        return (right + _mergeType * 10000, bottom + _mergeType * 10000, diag + _mergeType * 10000);
    }

    /**
     * Sets the image for a given token.  Requires payment of image manipulation price.  Image
     * manipulation price determinable with imageManipulationPrice view function.  Token can not
     * be locked.  To set the image using an IPFS CIDv1 in Base32 format, you can use the view 
     * function cidv1ToBytes to determine the data for the call.  
    */

    function setImage(uint256 tokenId, bytes30 _digest1, bytes30 _digest2, uint16 _length, bytes1 _multibase) external payable {
        require(redeemable, "Not yet active");
        require(msg.sender == ERC721.ownerOf(tokenId), "Not owner"); 
        require(msg.value == imageManipulationPrice(tokenId), "Invalid amount sent");
        RedeemedStruct memory redeemed = _tokenIdToRedeemed[tokenId];
        require(redeemed.redeemedAndLocked < 2, "Tile locked");
        redeemed.redeemedAndLocked = 1;
        redeemed.digest1 = _digest1;
        redeemed.digest2 = _digest2;
        redeemed.multibase = _multibase;
        redeemed.size = _length;
        _tokenIdToRedeemed[tokenId] = redeemed;
        emit TokenImageSet(tokenId, msg.sender, _digest1, _digest2, _multibase, _length, false);
    }

    /**
     * Permanently locks a token, including its image.  The token image can not be changed or unset.
     * The token can also no longer be merged or unmerged.  
    */
    function lockToken(uint256 tokenId) public {
        require(redeemable, "Not active");
        require(msg.sender == ERC721.ownerOf(tokenId), "Not owner"); 
        RedeemedStruct memory redeemed = _tokenIdToRedeemed[tokenId];
        require(redeemed.redeemedAndLocked != 2, "Already locked");
        require(redeemed.redeemedAndLocked == 1 && redeemed.digest1 != 0, "No image");
        redeemed.redeemedAndLocked = 2;
        _tokenIdToRedeemed[tokenId] = redeemed;
        emit TokenImageSet(tokenId, msg.sender, redeemed.digest1, redeemed.digest2, redeemed.multibase, redeemed.size, true);
    }

    /**
     * Removes the record of an image for a token.  Requires payment of imageManipulationPrice.
    */
    function unsetImage(uint256 tokenId) external payable {
        require(redeemable, "Not active");
        require(msg.sender == ERC721.ownerOf(tokenId), "Not owner"); 
        require(msg.value == imageManipulationPrice(tokenId), "Invalid amount sent");
        require(_tokenIdToRedeemed[tokenId].redeemedAndLocked != 2, "Tile locked");
        delete _tokenIdToRedeemed[tokenId];
        emit TokenImageSet(tokenId, msg.sender, 0x0, 0x0, "", 0, false);
    }

    /**
     *  Function for owner to set the url for a redeemed tile. 
     */
    function setTokenLinkUrl(uint256 tokenId, string memory url) external {
        require(redeemable, "Not active");
        require(msg.sender == ERC721.ownerOf(tokenId), "Not owner");
        require(_tokenIdToRedeemed[tokenId].redeemedAndLocked == 1, "Tile not redeemed or unlocked");
        _tokenIdToUrl[tokenId] = url;
        emit TokenUrlSet(tokenId, url);
    }

    /** 
     * Allows anyone to set tokens as redeemable upon sale completion for price of a token if owner
     * has not yet set as redeemable.
    */
    function initiateRedemption() external payable {
        require(totalSupply() == TILE_LIMIT, "Sale not yet complete");
        require(!redeemable, "Already redeemable");
        require(msg.value == _price, "Invalid amount");
        redeemable = true;
    }

    // Owner's functions
    function startSale(uint64 setPrice, uint8 maxMint, uint8 maxTotal) external onlyOwner {
        require(!_active, "Already active");
        _active = true;
        _price = setPrice;
        _maxMint = maxMint;
        _maxMintTotal = maxTotal;
    }

    function updateSaleParams(uint64 setPrice, uint8 maxMint, uint8 maxTotal) external onlyOwner {
        require(_active, "Not active");
        _price = setPrice;
        _maxMint = maxMint;
        _maxMintTotal = maxTotal;
    }
  
    function pauseSale(bool paused) external onlyOwner {
        _salePaused = paused;
    }

    function makeRedeemable() external onlyOwner {
        redeemable = true;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        _baseTokenURI = _uri;
    }

    function setContractURI(string memory contractURI_) external onlyOwner {
        _contractURI = contractURI_;
    }

    function promoMint(uint256 _tiles, address recipient) external onlyOwner {
        require(_active == false, "Sale already active");
        require(recipient != address(0), "No recipient");
        require(_tiles >= 1 && _tiles < 101, "Invalid mint amount");
        for (uint i = 0; i < _tiles; i++){
            _mintTo(recipient); 
        }
    }
    
    function renounceOwnership() public view override onlyOwner {
        revert("Not allowed");
    }

    function withdraw(address payable recipient, uint256 amount) external onlyOwner {
        recipient.transfer(amount);
    }

}

// SPDX-License-Identifier: UNKNOWN

pragma solidity ^0.8.0;

/**
 * @dev Base 32 operations.
 */
contract BaseConversion {

function _byteToUTF8(bytes1 _conv) private pure returns (string memory){
    bytes memory byteArray = new bytes(1);
    byteArray[0] = _conv;
    return string(byteArray);
}

function _get5BitsAsUint(bytes30 input, uint8 position) private pure returns (uint8){
    bytes30 temp = input;
    temp = temp << (position * 5);
    bytes30 mask = 0xf80000000000000000000000000000000000000000000000000000000000;
    temp = temp & mask;
    temp = temp >> 235;  // 32 * 8 - 5
    return uint8(uint240((temp)));
}

function _uintToChar(uint8 _conv, uint8 _addand) private pure returns (bytes1){
    if (_conv < 26){
        return bytes1(_conv + _addand);
    }
    else {
        return bytes1(_conv + 24);
    }
}

function _bytes30ToString(bytes30 input, uint8 length, bytes1 multibase) private pure returns (bytes memory){
    bytes memory bytesArray = new bytes(length);
    uint8 i = 0;
    uint8 addand = multibase == 0x42 ? 65 : 97;
    for(i = 0; i < length; i++){
        uint8 bit = _get5BitsAsUint(input, i);
        bytesArray[i] = _uintToChar(bit, addand);
    }
    return bytesArray;
}

function byteArraysToBase32String(bytes30 digest1, bytes30 digest2, bytes1 multibase, uint16 length) internal pure returns (string memory){
    if (length > 240){
        bytes memory string1 = _bytes30ToString(digest1, 48, multibase);
        bytes memory string2 = _bytes30ToString(digest2, uint8((length - 240) / 5), multibase);
        return string(bytes.concat(string1, string2));
    }
    else{
        return string(bytes.concat(_bytes30ToString(digest1, uint8(length / 5), multibase)));
    }
}

function base32stringToBytes(string memory input) internal pure returns (bytes30 digest1, bytes30 digest2, bytes1 multibase, uint16 length){
    bytes memory bytesArray =  bytes(input);
    uint i = 0;
    uint wordlength = bytesArray.length;
    
    multibase = bytesArray[0];
    uint8 firstByte = uint8(multibase);
    require(firstByte == 98 || firstByte == 66, "Invalid rfc4648 string");
    
    uint8 lower = firstByte - 2;
    uint8 upper = firstByte + 25;
    uint8 alpha = lower + 1;

    for(i = 0; i < wordlength; i++){
        uint8 thisByte = uint8(bytesArray[i]);
        
        require((thisByte > lower && thisByte < upper) || (thisByte > 49 && thisByte < 56), "Invalid base32 string");

        if (thisByte > (lower)){
            thisByte = thisByte - alpha;
        }
        else{
            thisByte = thisByte - 24;
        }

        bytes30 tempBytes = bytes30(uint240(thisByte));
        
        if (i<48){
            tempBytes = tempBytes << (5 * (47 - i));
            digest1 = digest1 | tempBytes;
        }
        else{
            tempBytes = tempBytes << (5 * (95 - i));
            digest2 = digest2 | tempBytes;
        }
        
    }
    return (digest1, digest2, multibase, uint16(wordlength * 5));
}

// Base64URL Functions

function _get6BitsAsUint(bytes30 input, uint8 position) private pure returns (uint8){
    bytes30 temp = input;
    temp = temp << (position * 6);
    bytes30 mask = 0xfc0000000000000000000000000000000000000000000000000000000000;
    temp = temp & mask;
    temp = temp >> 234;  // 32 * 8 - 6
    return uint8(uint240((temp)));
}

function _uintToChar(uint8 _conv) private pure returns (bytes1){
    if (_conv < 26){
        return bytes1(_conv + 65);
    }
    else if (_conv < 52) {
        return bytes1(_conv + 71);
    }
    else if (_conv < 62) {
        return bytes1(_conv - 4);
    }
    else if (_conv == 62) {
        return bytes1(_conv - 17);
    }
    else if (_conv == 63){
        return bytes1(_conv + 32);
    }
    else {
        revert();
    }
}

function _bytes30ToString(bytes30 input, uint8 length) private pure returns (bytes memory){
    bytes memory bytesArray = new bytes(length);
    uint8 i = 0;
    for(i = 0; i < length; i++){
        uint8 bit = _get6BitsAsUint(input, i);
        bytesArray[i] = _uintToChar(bit);
    }
    return bytesArray;
}

function byteArraysToBase64String(bytes30 digest1, bytes30 digest2, uint16 length) internal pure returns (string memory){
    if (length > 240){
        bytes memory string1 = _bytes30ToString(digest1, 40);
        bytes memory string2 = _bytes30ToString(digest2, uint8((length - 240) / 6));
        return string(bytes.concat(string1, string2));
    }
    else{
        return string(bytes.concat(_bytes30ToString(digest1, uint8(length / 6))));
    }
}

function base64URLstringToBytes(string memory input) internal pure returns (bytes30 digest1, bytes30 digest2, bytes1 multibase, uint16 length){
    bytes memory bytesArray =  bytes(input);
    uint i = 0;
    uint wordlength = bytesArray.length;
    
    multibase = 0x75;

    for(i = 0; i < wordlength; i++){
        uint8 thisByte = uint8(bytesArray[i]);
        
        if (thisByte == 95){
            thisByte = 63;
        }
        else if (thisByte == 45){
            thisByte = 62;
        }
        else if (thisByte > 96){
            thisByte = thisByte - 71;
        }
        else if (thisByte > 64) {
            thisByte = thisByte - 65;
        }
        else if (thisByte > 47 && thisByte < 58) {
            thisByte = thisByte + 4;
        }
        else {
            revert();
        }
        
        bytes30 tempBytes = bytes30(uint240(thisByte));
        
        if (i<40){
            tempBytes = tempBytes << (6 * (39 - i));
            digest1 = digest1 | tempBytes;
        }
        else{
            tempBytes = tempBytes << (6 * (79 - i));
            digest2 = digest2 | tempBytes;
        }
        
    }
    return (digest1, digest2, multibase, uint16((wordlength) * 6));
}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is ERC721, ContextMixin, NativeMetaTransaction, Ownable {
    using Counters for Counters.Counter;

    /**
     * We rely on the OZ Counter util to keep track of the next available ID.
     * We track the nextTokenId instead of the currentTokenId to save users on gas costs. 
     * Read more about it here: https://shiny.mirror.xyz/OUampBbIz9ebEicfGnQf5At_ReMHlZy0tB4glb9xQ0E
     */ 
    Counters.Counter private _nextTokenId;
    address _proxyRegistryAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        address proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        _proxyRegistryAddress = proxyRegistryAddress;
        // nextTokenId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
        _nextTokenId.increment();
        _initializeEIP712(_name);
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function _mintTo(address _to) internal {
        uint256 currentTokenId = _nextTokenId.current();
        _nextTokenId.increment();
        _mint(_to, currentTokenId);
    }

    /**
        @dev Returns the total tokens minted so far.
        1 is always subtracted from the Counter since it tracks the next available tokenId.
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }
/*
    function baseTokenURI() virtual public view returns (string memory);

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }
*/
    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {EIP712Base} from "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress] + 1;

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

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
        _setApprovalForAll(_msgSender(), operator, approved);
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
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Initializable} from "./Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contracts that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name
    )
        internal
        initializer
    {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}