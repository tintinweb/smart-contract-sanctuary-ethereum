// SPDX-License-Identifier:  CC-BY-NC-4.0
// email "contracts [at] pyxelchain.com" for licensing information
// Pyxelchain Technologies v0.3.0 (NFTGrid.sol)

pragma solidity =0.8.7;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "hardhat/console.sol";

/**
 * @title One Billion Pixel Project
 * @author Nik Cimino @ncimino
 *
 * @dev the 1 billion pixels are arranged in a 32768 x 32768 = 1,073,741,824 pixel matrix
 * to address all 1 billion pixels we break them into 256 pixel tiles which are 16 pixels x 16 pixels
 * this infers a grid based addressing sytem of dimensions: 32768 / 16 = 2048 x 2048 = 4,194,304 tiles
 *   
 * @notice to _significantly_ reduce gas we require that purchases are some increment of the layers defined above
 *
 * @notice this cotnract does not make use of ERC721Enumerable as the tokenIDs are not sequential
 */

/*
 * this contract is not concerned with the individual pixels, but with the tiles that can be addressed and sold
 * each tile is represented as an NFT, but each NFT can be different dimensions in layer 1 they are 1 tile each, but in layer 4 they are 16 tiles each
 *   layer 1:    1 x    1 =         1 tile / index
 *   layer 2:    2 x    2 =         4 tiles / index
 *   layer 3:    4 x    4 =        16 tiles / index
 *   layer 4:    8 x    8 =        64 tiles / index
 *   layer 5:   16 x   16 =       256 tiles / index
 *   layer 6:   32 x   32 =     1,024 tiles / index
 *   layer 7:   64 x   64 =     4,096 tiles / index
 *   layer 8:  128 x  128 =    16,384 tiles / index
 *   layer 9:  256 x  256 =    65,536 tiles / index
 *  layer 10:  512 x  512 =   262,144 tiles / index
 *  layer 11: 1024 x 1024 = 1,048,576 tiles / index
 *  layer 12: 2048 x 2048 = 4,194,304 tiles / index
 * 
 * quad alignment:
 *
 *      layer 11    layer 12
 *      ____N___   ________
 *     /   /   /  /       /
 *   W/---+---/E /       /
 *   /___/___/  /_______/
 *       S
 */


contract NFTGrid is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    //// TYPES & STRUCTS

    /**
     * @dev symetric: should be kept up-to-date with JS implementation
     * @notice layers enum interger value is used as 2 ^ Layer e.g. 2 ^ (x4=2) = 5, 2 ^ (x16=4) = 16
     *  there are a total of 12 sizes (0-11)
     * @dev these enums are uint256 / correct?
     */
    enum Size {
        X1,
        X2,
        X4,
        X8,
        X16,
        X32,
        X64,
        X128,
        X256,
        X512,
        X1024,
        X2048
    } // 2048 = 2^11 = 1 << 11

    /**
     * max x and y is 2048 = 2 ^ 11 which can fit in a uint16, but since we only need 4 values using 64 is fine and packs tight
     *
     * we model our grid system in the same what that the front-end displays are modeled, this is with 0,0 in the top left corner
     * x increases as we move to the right, but y increases as we move done
     *
     * we model this so that we have logical coherency between our internal logic and the display systems of this logic
     *
     * x & y are the center of the quad
     */
    struct Rectangle {
        uint16 x;
        uint16 y;
        uint16 w;
        uint16 h;
    }

    /**
     * a quad cannot be owned after it has been divided
     * @dev the quads are the tokenIds which are an encoding of x,y,w,h
     */
    struct QuadTree {
        uint64 northeast;   // quads max index is 2 ^ 64 = 18,446,744,073,709,551,616
        uint64 northwest;   // however, this allows us to pack all 4 into a 256 bit slot
        uint64 southeast;
        uint64 southwest;
        Rectangle boundary; // 16 * 4 = 64 bits
        address owner;      // address are 20 bytes = 160 bits
        bool divided;       // bools are 1 byte = 8 bits  ... should also pack into a 256 bit slot, right? so 2 total?
        uint24 ownedCount;  // need 22 bits to represent full 2048x2048 count - total number of grid tiles owned under this quad (recursively)
    }

    //// EVENTS

    event ETHPriceChanged (
        uint256 oldPrice, uint256 newPrice
    );

    event TokensUpdated (
        address[] tokenAddresses, uint256[] tokenPrices
    );

    event BuyCreditWithETH (
        address buyer, address receiver, uint256 amountETH, uint256 amountPixels
    );

    event BuyCreditWithToken (
        address buyer, address receiver, uint256 amountToken, uint256 amountPixels
    );

    //// MODIFIERS

    modifier placementNotLocked() {
        require(!placementLocked, "NFTG: placement locked");
        _;
    }

    modifier reserveNotLocked() {
        require(!reserveLocked, "NFTG: reserve locked");
        _;
    }

    //// MEMBERS

    uint16 constant public GRID_W = 2048;
    uint16 constant public GRID_H = 2048;
    uint256 constant public PIXELS_PER_TILE = 256;

    bool public placementLocked;
    bool public reserveLocked;
    uint64 immutable public rootTokenId;
    uint256 public pricePerPixelInETH = 0.00004 ether;
    address[] public tokenAddresses; // e.g. USDC can be passed in @ $0.10/pixel = $25.60 per tile
    address[] public receivedAddresses;
    mapping (uint64 => QuadTree) public qtrees;
    mapping (address => uint256) public pricePerPixelInTokens;
    mapping (address => bool) public addressExists;
    mapping (address => uint256) public pixelCredits;
    mapping (address => uint256) public ownedPixels;
    mapping (uint256 => string) public tokenUris;
    string public defaultURI;
    uint256 public totalPixelsOwned;

    //// CONTRACT

    constructor(address[] memory _tokenAddresses, uint256[] memory _tokenPrices) ERC721("Billion Pixel Project", "BPP") {
        updateTokens(_tokenAddresses, _tokenPrices);
        uint64 qtreeTokenId = _createQTNode(address(0x0), GRID_W/2-1, GRID_H/2-1, GRID_W, GRID_H);
        rootTokenId = qtreeTokenId;
        _subdivideQTNode(qtreeTokenId);
    }

    function getTokens() external view returns(address[] memory addresses, uint256[] memory prices) {
        addresses = new address[](tokenAddresses.length);
        prices = new uint256[](tokenAddresses.length);
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            address current = tokenAddresses[i];
            addresses[i] = current;
            prices[i] = pricePerPixelInTokens[current];
        }
    }

    /**
     * @notice let each token have an independent URI as these will be owned and controlled by their owner
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory uri) {
        require(_exists(_tokenId), "NFTG: non-existant token");
        uri = tokenUris[_tokenId];
        if (bytes(uri).length == 0) {
            uri = bytes(defaultURI).length > 0 ? string(abi.encodePacked(defaultURI, _tokenId.toString())) : "";
        }
    }

    function setDefaultURI(string memory uri) external onlyOwner {
        defaultURI = uri;
    }

    function setTokenURI(uint256 _tokenId, string calldata _tokenUri) external virtual {
        require(_exists(_tokenId), "NFTG: non-existant token");
        QuadTree storage qtree = qtrees[uint64(_tokenId)];
        require(qtree.owner == msg.sender, "NFTG: only owner can set URI");
        tokenUris[_tokenId] = _tokenUri;
    }

    function updateTokens(address[] memory _tokenAddresses, uint256[] memory _tokenPrices) public onlyOwner {
        require(_tokenAddresses.length == _tokenPrices.length, "NFTG: array length mismatch");
        tokenAddresses = _tokenAddresses;
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            require(_tokenAddresses[i] != address(0), "NFTG: token address 0");
            require(_tokenPrices[i] != 0, "NFTG: token price 0");
            pricePerPixelInTokens[_tokenAddresses[i]] = _tokenPrices[i];
        }
        emit TokensUpdated(_tokenAddresses, _tokenPrices);
    }

    function togglePlacementLock() external onlyOwner {
        placementLocked = !placementLocked;
    }

    function toggleReserveLock() external onlyOwner {
        reserveLocked = !reserveLocked;
    }

    function setETHPrice(uint256 _pricePerPixel) external onlyOwner {
        emit ETHPriceChanged(pricePerPixelInETH, _pricePerPixel);
        pricePerPixelInETH = _pricePerPixel;
    }

    function getPixelCredits() external view returns(address[] memory addresses, uint256[] memory balances) {
        addresses = new address[](receivedAddresses.length);
        balances = new uint256[](receivedAddresses.length);
        for (uint256 i = 0; i < receivedAddresses.length; i++) {
            address current = receivedAddresses[i];
            addresses[i] = current;
            balances[i] = pixelCredits[current];
        }
    }

    /**
     * @notice purchases are blocked if a child block is owned by current buyer
     * a user must aquire blocks on the same layer and combine to create the higher layers
     * @param _tokenId the tokenId of the quad to buy using Tokens
     */
    function buyWithToken(address _tokenAddress, uint64 _tokenId) external nonReentrant placementNotLocked {
        _buyWithToken(_tokenAddress, _tokenId);
    }

    /**
     * @param _tokenIds the tokenIds of the quads to buy using Tokens
    */
    function multiBuyWithToken(address _tokenAddress, uint64[] calldata _tokenIds) external nonReentrant placementNotLocked {
        for(uint i = 0; i < _tokenIds.length; i++) {
            _buyWithToken(_tokenAddress, _tokenIds[i]);
        }
    }

    function _buyWithToken(address _tokenAddress, uint64 _tokenId) private {
        uint256 pricePerPixel = pricePerPixelInTokens[_tokenAddress];
        require(pricePerPixel != 0, "NFTG: token not supported");
        Rectangle memory range = getRangeFromTokenId(_tokenId);
        uint256 price = _price(pricePerPixel, range);
        _buyCreditWithToken(_tokenAddress, msg.sender, price);
        _placeQTNode(_tokenId);
    }

    /**
     * @notice purchases are blocked if a child block is owned by current buyer
     * a user must aquire blocks on the same layer and combine to create the higher layers
     * @param _tokenId the tokenId of the quad to buy using ETH
     */
    function buyWithETH(uint64 _tokenId) external payable nonReentrant placementNotLocked {
        _buyCreditWithETH(msg.sender);
        _placeQTNode(_tokenId);
    }

    /**
     * @param _tokenIds the tokenIds of the quads to buy using ETH
    */
    function multiBuyWithETH(uint64[] calldata _tokenIds) external payable nonReentrant placementNotLocked {
        _buyCreditWithETH(msg.sender);
        for(uint i = 0; i < _tokenIds.length; i++) {
            _placeQTNode(_tokenIds[i]);
        }
    }

    function _placeQTNode(uint64 _tokenId) private {
        Rectangle memory range = getRangeFromTokenId(_tokenId);
        uint256 pixelsToPlace = uint256(range.w) * uint256(range.h) * PIXELS_PER_TILE;
        uint256 pixelBalance = pixelCredits[msg.sender];
        require(pixelsToPlace <= pixelBalance, "NFTG: not enough credit");
        pixelCredits[msg.sender] -= pixelsToPlace;
        _mintQTNode(_tokenId);
    }

    /**
     * @notice the amount of {msg.value} is what will be used to convert into pixel credits
     * @param _receiveAddress is the address receiving the pixel credits
     */
    // slither-disable-next-line reentrancy-events
    function buyCreditWithETH(address _receiveAddress) external payable nonReentrant reserveNotLocked {
        _buyCreditWithETH(_receiveAddress);
    }

    function _buyCreditWithETH(address _receiveAddress) private {
        uint256 credit = msg.value / pricePerPixelInETH;
        require(credit > 0, "NFTG: not enough ETH sent");
        emit BuyCreditWithETH(msg.sender, _receiveAddress, msg.value, credit);
        pixelCredits[_receiveAddress] += credit;
        ownedPixels[_receiveAddress] += credit;
        totalPixelsOwned += credit;
        if (!addressExists[_receiveAddress]) {
            receivedAddresses.push(_receiveAddress); 
            addressExists[_receiveAddress] = true;
        }
        Address.sendValue(payable(owner()), msg.value);
    }

    /**
     * @param _tokenAddress is the address of the token being used to purchase the pixels
     * @param _receiveAddress is the address receiving the pixel credits
     * @param _amount is the amount in tokens - if using a stable like USDC, then this represent dollar value in wei
     */
    function buyCreditWithToken(address _tokenAddress, address _receiveAddress, uint256 _amount) external nonReentrant reserveNotLocked {
        _buyCreditWithToken(_tokenAddress, _receiveAddress, _amount);
    }

    function _buyCreditWithToken(address _tokenAddress, address _receiveAddress, uint256 _amount) private {
        uint256 pricePerPixel = pricePerPixelInTokens[_tokenAddress];
        require(pricePerPixel != 0, "NFTG: token not supported");
        uint256 credit = _amount / pricePerPixel;
        require(credit > 0, "NFTG: not enough tokens sent");
        emit BuyCreditWithToken(msg.sender, _receiveAddress, _amount, credit);
        pixelCredits[_receiveAddress] += credit;
        ownedPixels[_receiveAddress] += credit;
        totalPixelsOwned += credit;
        if (!addressExists[_receiveAddress]) {
            receivedAddresses.push(_receiveAddress); 
            addressExists[_receiveAddress] = true;
        }
        IERC20(_tokenAddress).safeTransferFrom(msg.sender, owner(), _amount);
    }

    /**
     * @notice allows already purchased pixels to be allocated to specific token IDs
     * @dev will fail if pixel balance is insufficient
     * @param _tokenIds the tokenIds of the quads to place
     */
    function placePixels(uint64[] calldata _tokenIds) external nonReentrant placementNotLocked {
        for(uint i = 0; i < _tokenIds.length; i++) {
            _placeQTNode(_tokenIds[i]);
        }
    }

    /**
     * @dev only the leafs can be purchased
     * @dev quads are only divided if someone has owns a child (via subdivde or buyWith*)
     */
    function _mintQTNode(uint64 _tokenId) private {
        QuadTree storage qtree = qtrees[uint64(_tokenId)];
        require(!qtree.divided, "NFTG: cannot buy if divided");
        require(qtree.owner == address(0x0), "NFTG: already owned");
        
        revertIfParentOwned(_tokenId);
        _revertIfChildOwned(qtree); // needed if burning
        Rectangle memory range = getRangeFromTokenId(_tokenId);
        uint24 increaseCount = uint24(range.w) * uint24(range.h);
        _divideAndCount(getParentTokenId(_tokenId), increaseCount);
        
        qtree.owner = msg.sender;
        qtree.ownedCount = increaseCount;

        _safeMint(msg.sender, _tokenId);
    }

    function _price(uint256 _pricePerPixel, Rectangle memory _rect) private pure returns(uint256 price) {
        price = _pricePerPixel * PIXELS_PER_TILE * uint256(_rect.w) * uint256(_rect.h);
    }
    
    /**
     * @notice override the ERC720 function so that we can update user credits
     * @dev this logic only executes if pixels are being transferred from one user to another
     * @dev this contract doesn't support burning of these NFTs so we don't need to subtract on burn (_to == 0)
     * @dev this contract increases the owned count on reserve not on minting (_from == 0) we ignores those as they are already added
     */
    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal virtual override {
        if ((_from != address(0)) && (_to != address(0))) {
            Rectangle memory range = getRangeFromTokenId(uint64(_tokenId));
            uint256 credit = uint256(range.w) * uint256(range.h) * PIXELS_PER_TILE;
            ownedPixels[_from] -= credit;
            ownedPixels[_to] += credit;
        }
    }

    /**
     * @notice calculates the price of multiple quads in ETH
     * @param _tokenIds the tokenIds of the quads to get the ETH prices of
     */
    // function getMultiETHPrice(uint64[] calldata _tokenIds) external view returns(uint price) {
    //     for(uint i = 0; i < _tokenIds.length; i++) {
    //         price += getETHPrice(_tokenIds[i]);
    //     }
    // }

    /**
     * @notice calculates the price of a quad in ETH
     * @param _tokenId the tokenId of the quad to get the ETH price of
     */
    function getETHPrice(uint64 _tokenId) external view returns(uint price) {
        Rectangle memory range = getRangeFromTokenId(_tokenId);
        price = _price(pricePerPixelInETH, range);
    }

    /**
     * @notice calculates the price of multiple quads in tokens
     * @param _tokenIds the tokenIds of the quads to get the token prices of
     */
    // function getMultiTokenPrice(uint64[] calldata _tokenIds) external view returns(uint price) {
    //     for(uint i = 0; i < _tokenIds.length; i++) {
    //         price += getTokenPrice(_tokenIds[i]);
    //     }
    // }

    /**
     * @notice calculates the price of a quad in Tokens
     * @param _tokenId the tokenId of the quad to get the Token price of
     */
    function getTokenPrice(address _tokenAddress, uint64 _tokenId) external view returns(uint price) {
        uint256 pricePerPixel = pricePerPixelInTokens[_tokenAddress];
        require(pricePerPixel != 0, "NFTG: token not supported");
        Rectangle memory range = getRangeFromTokenId(_tokenId);
        price = _price(pricePerPixel, range);
    }

    /**
     * @notice this function subdivides the quad 
     * @dev don't need to check the qtree of X2048 was divided in ctor
     */
    function _divideAndCount(uint64 _tokenId, uint24 _increaseBy) private {
        QuadTree storage qtree = qtrees[_tokenId];
        if (_tokenId != rootTokenId) {
            uint64 parentTokenId = getParentTokenId(_tokenId);
            _divideAndCount(parentTokenId, _increaseBy);
        }
        if (!qtree.divided) {
            _subdivideQTNode(_tokenId);
        }
        qtree.ownedCount += _increaseBy;
    }

    /**
     * useful for checking if any child is owned
     */
    function revertIfChildOwned(uint64 _tokenId) external view {
        QuadTree memory qtree = qtrees[_tokenId];
        _revertIfChildOwned(qtree);
    }

    function _revertIfChildOwned(QuadTree memory _qtree) private pure {
        require(_qtree.ownedCount == 0, "NFTG: child owned");
    }

    /**
     * useful for checking if any parent is owned
     */
    function revertIfParentOwned(uint64 _tokenId) public view {
        uint64 parentTokenId = _tokenId;
        while (parentTokenId != rootTokenId) { // NOTE: don't need to check the parent of X2048
            parentTokenId = getParentTokenId(parentTokenId);
            QuadTree memory parent = qtrees[parentTokenId];
            require(parent.owner == address(0x0), "NFTG: parent owned");
        }
    }

    /**
     * @dev symetric: should be kept up-to-date with JS implementation
     * @notice calculates a parent tile tokenId from a child - it is known that the parents w/h will be 2x the child,
     * and from that we can determine the quad using it's x/y
     * @param _tokenId the tokenId of the quad to get the parent range of
     */
    function getParentRange(uint64 _tokenId) public pure returns(Rectangle memory parent) {
        // parent is child until assignment (to save gas)...
        parent = getRangeFromTokenId(_tokenId);
        uint16 width = 2 * parent.w;
        uint16 height = 2 * parent.h;
        uint16 tileIndexX = calculateIndex(parent.x, parent.w);
        uint16 tileIndexY = calculateIndex(parent.y, parent.h);
        // slither-disable-next-line divide-before-multiply
        parent.x = tileIndexX / 2 * width + width / 2 - 1; // note: division here truncates and this is intended when going to indexes
        // slither-disable-next-line divide-before-multiply
        parent.y = tileIndexY / 2 * height + height / 2 - 1;
        parent.w = width;
        parent.h = height;
        validate(parent);
    }

    /**
     * index layout:
     *    layer 11    layer 12
     *      _0___1__   ____0___
     *   0 /   /   /  /       /
     *    /---+---/ 0/       /
     * 1 /___/___/  /_______/
     * x=127+256,y=127 w=256   x=0,y=0 w=1  special case for dimension of 1 since we move up and left
     * x=w/2-1+index*w         x=index*w
     * index*w=x-w/2+1
     * index=(x-w/2+1)/w
     */

    /**
     * @dev this function does not check values - it is presumed that the values have already passed 'validate'
     * @param _value is x or y
     * @param _dimension is w or h (respectively)
     * @return index is the index starting at 0 and going to w/GRID_W - 1 or h/GRID_H - 1
     *      the indexes of the tiles are the tokenId of the column or row of that tile (based on dimension)
     */

    function calculateIndex(uint16 _value, uint16 _dimension) public pure returns(uint16 index) {
        index = (_dimension == 1) ? (_value / _dimension) : ((_value + 1 - _dimension/2) / _dimension);
    }

    /**
     * @dev symetric: should be kept up-to-date with JS implementation
     * @notice calculates a parent tile tokenId from a child
     * @param _tokenId the tokenId of the quad to get the parent range of
     */
    function getParentTokenId(uint64 _tokenId) public pure returns(uint64 parentTokenId) {
        parentTokenId = getTokenIdFromRangeNoCheck(getParentRange(_tokenId));
    }

    /**
     * @notice splits a tile into a quarter (a.k.a. quad)
     * @dev there are ne, nw, se, sw quads on the QuadTrees
     * @notice the quads are stored as tokenIds here not actual other QuadTrees
     */
    function subdivide(uint256 _tokenId) external placementNotLocked { 
        QuadTree memory qtree = qtrees[uint64(_tokenId)];
        require(!qtree.divided, "NFTG: already divided");
        require(qtree.owner == msg.sender, "NFTG: only owner can subdivide");
        _subdivideQTNode(uint64(_tokenId));
    }

    /**
     * @notice quad coordinates are at the center of the quad - this make dividing coords relative...
     * for root: x=1023, y=1023, w=2048, h=2048
     *  wChild = wParent/2 = 1024
     *  currently: xParent + wChild/2 = xParent + wParent/4 > 1023 + 512 = 1535
     * @dev special care was taken when writing this function so that this function does not transfer any ownership!
     */
    function _subdivideQTNode(uint64 _tokenId) private { 
        QuadTree storage qtree = qtrees[_tokenId];
        uint16 x = qtree.boundary.x;
        uint16 y = qtree.boundary.y;
        uint16 w = qtree.boundary.w;
        uint16 h = qtree.boundary.h;
        require(w > 1 && h > 1, "NFTG: cannot divide"); // cannot divide w or h=1 and 0 is not expected
        if (qtree.owner != address(0x0)) {
            _burn(uint256(_tokenId));
        }
        // special case for w|h=2
        // X2:0,0:x,y = 1,0 & 0,0 & 1,1 & 0,1
        // X2:1,0:x,y = 2,0 & 2,0 & 2,2 & 0,2
        // X2:1,1:x,y = 2,1 & 1,1 & 2,2 & 1,2
        // X2:2,2:x,y = 4,3 & 3,3 & 4,4 & 3,4
        if ((w == 2) || (h==2)) {
            qtree.northeast = _createQTNode(qtree.owner, x + 1, y - 0, w/2, h/2);
            qtree.northwest = _createQTNode(qtree.owner, x - 0, y - 0, w/2, h/2);
            qtree.southeast = _createQTNode(qtree.owner, x + 1, y + 1, w/2, h/2);
            qtree.southwest = _createQTNode(qtree.owner, x - 0, y + 1, w/2, h/2);
        } else {
            qtree.northeast = _createQTNode(qtree.owner, x + w/4, y - h/4, w/2, h/2);
            qtree.northwest = _createQTNode(qtree.owner, x - w/4, y - h/4, w/2, h/2);
            qtree.southeast = _createQTNode(qtree.owner, x + w/4, y + h/4, w/2, h/2);
            qtree.southwest = _createQTNode(qtree.owner, x - w/4, y + h/4, w/2, h/2);
        }
        qtree.divided = true;
        qtree.owner = address(0x0);
    }

    /**
     * @notice creates a QuadTree 
     * @return tokenId the tokenId of the quad
     */
    function _createQTNode(address _owner, uint16 _x, uint16 _y, uint16 _w, uint16 _h) private returns(uint64 tokenId) {
        Rectangle memory boundary = Rectangle(_x, _y, _w, _h);
        // console.log("_x", _x, "_y", _y);
        // console.log("_w", _w, "_h", _h);
        tokenId = getTokenIdFromRange(boundary);
        QuadTree storage qtree = qtrees[tokenId];
        qtree.boundary = boundary;
        qtree.owner = _owner;
        if (_owner != address(0)) {
            _safeMint(_owner, tokenId);
        }
    }

    /**
     * @dev symetric: should be kept up-to-date with JS implementation
     * entokenIdd tokenId: 0x<X:2 bytes>_<Y:2 bytes>_<W:2 bytes>_wers of 2 are 0x1 = 1, 0x10 = 2, 0x100 = 4, etc.
     *    4: 0x100 & (0x100 - 1) = 0x100 & 0x011 = 0x000
     * negative tests:
     *    7: 0x111 & (0x111 - 1) = 0x111 & 0x110 = 0x110
     *    5: 0x101 & (0x101 - 1) = 0x101 & 0x100 = 0x100
     * @notice for the x & y validation, these values are always in the middle of the first tile (0.5 * w, 0.5 * h) and are then at increments of w & h
     * there for we can use the modulo operator and check that the remainder is precisely the offset:
     * @notice we offset x & y left one and up one so that for X1 the w=1/h=1 has x=0/y=0 and just as well for X2 w=2/h=2 has x=0,y=0
     *    the x & y values range from 0:w-1 and 0:h-1
     *    special care should be taken around w=1 and w=2 as the first tile for both is at x=0 and y=0 and
     *      for w=1 max x&y=2047 for w=2 max x&y=2046
     *<H:2 bytes> = 8 bytes = 64 bits (4 hex represent 2 bytes)
     * to get x we right shift by 6 bytes: 0x0000_0000_0000_<X:2 bytes>
     * to get y we right shift by 4 bytes & 0xFFFF: 0x0000_0000_<X:2 bytes>_<Y:2 bytes> & 0xFFFF = 0x0000_0000_0000_<Y:2 bytes>
     */
    function getRangeFromTokenId(uint64 _tokenId) public pure returns(Rectangle memory range) {
        uint16 mask = 0xFFFF;
        range.x = uint16((_tokenId >> 6 * 8) & mask);
        range.y = uint16((_tokenId >> 4 * 8) & mask);
        range.w = uint16((_tokenId >> 2 * 8) & mask);
        range.h = uint16(_tokenId & mask);
        validate(range);
    }

    /**
     * @dev symetric: should be kept up-to-date with JS implementation
     * entokenIdd tokenId: 0x<X:2 bytes><Y:2 bytes><W:2 bytes><H:2 bytes> = 8 bytes = 64 bits
     */
    function getTokenIdFromRange(Rectangle memory _range) public pure returns(uint64 tokenId) {
        validate(_range);
        tokenId = getTokenIdFromRangeNoCheck(_range);
    }

    function getTokenIdFromRangeNoCheck(Rectangle memory _range) private pure returns(uint64 tokenId) {
        tokenId = (uint64(_range.x) << 6 * 8) + (uint64(_range.y) << 4 * 8) + (uint64(_range.w) << 2 * 8) + uint64(_range.h);
    }

    /**
     * @dev symetric: should be kept up-to-date with JS implementation
     * @notice the w and h must be a power of 2 and instead of comparing to all of the values in the enum, we just check it using:
     *    N & (N - 1)  this works because all powers of 2 are 0x1 = 1, 0x10 = 2, 0x100 = 4, etc.
     *    4: 0x100 & (0x100 - 1) = 0x100 & 0x011 = 0x000
     * negative tests:
     *    7: 0x111 & (0x111 - 1) = 0x111 & 0x110 = 0x110
     *    5: 0x101 & (0x101 - 1) = 0x101 & 0x100 = 0x100
     * @notice for the x & y validation, these values are always in the middle of the first tile (0.5 * w, 0.5 * h) and are then at increments of w & h
     * there for we can use the modulo operator and check that the remainder is precisely the offset:
     * @notice we offset x & y left one and up one so that for X1 the w=1/h=1 has x=0/y=0 and just as well for X2 w=2/h=2 has x=0,y=0
     *    the x & y values range from 0:w-1 and 0:h-1
     *    special care should be taken around w=1 and w=2 as the first tile for both is at x=0 and y=0 and
     *      for w=1 max x&y=2047 for w=2 max x&y=2046
     */
    function validate(Rectangle memory _range) public pure {
        require((_range.x <= GRID_W - 1), "NFTG: x is out-of-bounds");
        require((_range.y <= GRID_H - 1), "NFTG: y is out-of-bounds");
        require((_range.w > 0), "NFTG: w must be greater than 0");
        require((_range.h > 0), "NFTG: h must be greater than 0");
        require((_range.w <= GRID_W), "NFTG: w is too large");
        require((_range.h <= GRID_H), "NFTG: h is too large");
        require((_range.w & (_range.w - 1) == 0), "NFTG: w is not a power of 2"); 
        require((_range.h & (_range.h - 1) == 0), "NFTG: h is not a power of 2");
        uint16 xMidOffset = _range.w / 2; // for w=1 xmid=0, w=2 xmid=1, w=4 xmid=2, etc.
        uint16 yMidOffset = _range.h / 2;
        // for w=1 and x=2047: (2047+1)%1=0, w=2 and x=1023: (1023+1)%2=0, w=4 and x=255: (255+1)%4=0
        require(((_range.x + 1) % _range.w) == xMidOffset, "NFTG: x is not a multiple of w");
        require(((_range.y + 1) % _range.h) == yMidOffset, "NFTG: y is not a multiple of h");
    }

    //// BOILERPLATE
    
    // receive eth with no calldata
    // see: https://blog.soliditylang.org/2020/03/26/fallback-receive-split/
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    // receive eth with no function match
    fallback() external payable {}

    function withdraw() external onlyOwner {
        address payable owner = payable(owner());
        owner.transfer(address(this).balance);
    }

    function withdrawToken(address _token, uint _amount) external onlyOwner {
        IERC20(_token).safeTransfer(owner(), _amount);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

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

        _afterTokenTransfer(address(0), to, tokenId);
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

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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