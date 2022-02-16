// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



// File @openzeppelin/contracts/access/[email protected]

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


import "./ERC721A.sol";

// map statique fixée 1x1 2x2 3x3 5x5 + morceaux non achetables, 
// reserve supply non mintable pour minter en x,y plus tard
// random tiles reveal post mint
// emit event every reveal/mint + modif z emit + transfers

// fonction mint random sur supply fixe
// function mint sur autre supply

contract OM is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    event mintToken(address _from, uint256 _id, uint256 _timestamp);
    event revealToken(uint256 _id, int256 x, int256 y);
    event mint(address _from, bytes32 _id, uint _value);

    string private baseURI;
    string private blindURI;
    uint256 public constant BUY_LIMIT_PER_TX = 10;
    uint256 public constant MAX_NFT_PUBLIC = 10000;
    uint256 private constant MAX_NFT = 10000;
    uint256 public NFTPrice = 0.002 ether;
    bool public reveal;
    bool public isActive;
    bool public isPresaleActive;
    uint256 public giveawayCount;

    struct Tile {
        int256 x;
        int256 y;
        uint256 z;
        uint256 ownerTokenId;
        uint16 size;
    }
    struct Coord {
        int256 x;
        int256 y;
    }
    struct mintInfo {
        uint256 timestamp;
        uint256 num;
        address addr;
    }
    mapping (int256 => mapping(int256 => Tile)) public map;
    mapping (uint256 => Coord) public tokenToTile;
    mapping (uint256 => mintInfo) public tokenToMintInfo;
    Coord[] public prestoredMap;
    uint256 salt;

    constructor() ERC721A("OM", "OM", 10) {
        // prestoredMap = [Coord(-2,-2), Coord(-2,-1), Coord(-2,0), Coord(-2,1), Coord(-2,2), Coord(-1,-2), Coord(-1,-1), 
        // Coord(-1,0), Coord(-1,1), Coord(-1,2), Coord(0,-2), Coord(0,-1), Coord(0,0), Coord(0,1), Coord(0,2), Coord(1,-2), 
        // Coord(1,-1), Coord(1,0), Coord(1,1), Coord(1,2), Coord(2,-2), Coord(2,-1), Coord(2,0), Coord(2,1), Coord(2,2)];
    }

    function setPrestoredMap(int256[] memory xs, int256[] memory ys)
        external 
        onlyOwner 
    {
        for (uint256 i; i < xs.length; i++){
            prestoredMap.push(Coord(xs[i], ys[i]));
        }
    }
    /*
     * Function to reveal
    */
    function revealNow() 
        external 
        onlyOwner 
    {
        reveal = true;
    }


    /*
     * Function setIsActive to activate/desactivate the smart contract
    */
    function setIsActive(
        bool _isActive
    ) 
        external 
        onlyOwner 
    {
        isActive = _isActive;
    }

    /*
     * Function setPresaleActive to activate/desactivate the whitelist/raffle presale  
    */
    function setPresaleActive(
        bool _isActive
    ) 
        external 
        onlyOwner 
    {
        isPresaleActive = _isActive;
    }
    
    /*
     * Function to set Base and Blind URI 
    */
    function setURIs(
        string memory _blindURI, 
        string memory _URI
    ) 
        external 
        onlyOwner 
    {
        blindURI = _blindURI;
        baseURI = _URI;
    }
    
    /*
     * Function to withdraw collected amount during minting by the owner
    */
    function withdraw(
    ) 
        public 
        onlyOwner 
    {
        uint balance = address(this).balance;
        require(balance > 0, "Balance should be more then zero");
        payable(address(0x9c22e408dfEB4e02c01cC7593Df39119E2D49A4F)).transfer(balance);
    }

    function mintTilesBlind(
        uint256 _numOfTokens
    )
        public
        payable
    {
        require(isActive, 'Contract is not active');
        require(!isPresaleActive, 'Presale is still active');
        require(_numOfTokens <= BUY_LIMIT_PER_TX, "Cannot mint above limit");
        require(totalSupply().add(_numOfTokens).sub(giveawayCount) <= MAX_NFT_PUBLIC, "Purchase would exceed max public supply of NFTs");
        require(NFTPrice.mul(_numOfTokens) == msg.value, "Ether value sent is not correct");
            for (uint i = totalSupply(); i < totalSupply().add(_numOfTokens); i++){
                tokenToMintInfo[i] = mintInfo(block.timestamp, i, msg.sender);
                emit mintToken(msg.sender, i, block.timestamp);
        }
        _safeMint(msg.sender, _numOfTokens);
    }

    function mintOneTile(
        int256 x,
        int256 y
    )
        public
        payable
    {
        require(isActive, 'Contract is not active');
        require(!isPresaleActive, 'Presale is still active');
        require(1 <= BUY_LIMIT_PER_TX, "Cannot mint above limit");
        require(totalSupply().add(1).sub(giveawayCount) <= MAX_NFT_PUBLIC, "Purchase would exceed max public supply of NFTs");
        require(NFTPrice.mul(1) == msg.value, "Ether value sent is not correct");
            map[x][y] = Tile(x, y, 0, totalSupply(), 1);
        tokenToTile[totalSupply()] = Coord(map[x][y].x, map[x][y].y);
        emit mintToken(msg.sender, totalSupply(), block.timestamp);
        emit revealToken(totalSupply(), x, y);
        _safeMint(msg.sender, 1);
    }

    /*
     * Function to get token URI of given token ID
     * URI will be blank untill totalSupply reaches MAX_NFT_PUBLIC
    */
    function tokenURI(
        uint256 _tokenId
    )
        public 
        view 
        virtual 
        override 
        returns (string memory)
    {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (!reveal) {
            return string(abi.encodePacked(blindURI));
        } else {
            return string(abi.encodePacked(baseURI, _tokenId.toString()));
        }
    }

    function ownerOfTile(int256 x, int256 y) public view returns (address) {
        return ownerOf(map[x][y].ownerTokenId);
    }

    function getTileFromToken(uint256 tokenId) public view returns (Tile memory) {
        return map[tokenToTile[tokenId].x][tokenToTile[tokenId].y];
    }

    function revealTile(uint256 tokenId) public {
        mintInfo memory mintInf = tokenToMintInfo[tokenId];
        uint256 rand = getRand(mintInf.timestamp, mintInf.num, mintInf.addr);
        map[tokenToTile[tokenId].x][tokenToTile[tokenId].y] = Tile(prestoredMap[rand%prestoredMap.length].x, 
        prestoredMap[rand%prestoredMap.length].y, 1, tokenId, 1);
        emit revealToken(tokenId, prestoredMap[rand%prestoredMap.length].x, prestoredMap[rand%prestoredMap.length].y);
        if (prestoredMap.length < 2){
            removeItem(rand%prestoredMap.length);
        }
    }

    function getRand(uint256 a, uint256 b, address from) private view returns (uint256) {
        uint256 h = uint256(keccak256(abi.encodePacked(a, b, from, salt)));
        return h;
    }

    function setSalt(uint256 _salt) public onlyOwner() {
        salt = _salt;
    }

    function removeItem(uint i) private {
        prestoredMap[i] = prestoredMap[prestoredMap.length - 1];
        prestoredMap.pop();
  }
}