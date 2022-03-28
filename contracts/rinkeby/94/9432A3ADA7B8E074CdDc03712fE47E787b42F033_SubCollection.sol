// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";



contract SubCollection is ERC721Enumerable, Ownable {

    using SafeMath for uint256;
    using Strings for uint256;

    // Time of when the sale starts.
    uint256 public blockStart;

    // Maximum amount of Buffalos in existance. 
    uint256 public MAX_SUPPLY = 1;
    uint256 public maxMintAmount;
    uint256 public mintedAmount;
    
    address public artist;
    address public masterContract;
    string public baseURI;
    string public uri;
    string public metaDataExt = ".json";

    mapping(address => uint256) mintedPerAddress;
    mapping(uint256 => bool) public isTokenIdExisting;

    bool public mintable = true;

    event SubCollectionBought (address buyer, uint256 id);

    modifier onlyContract() {
        require(masterContract == msg.sender, "Only contract calls this function.");
        _;
    }

    constructor(
        string memory name, 
        string memory symbol, 
        string memory URI,
        uint256 initialSupply, 
        uint256 startDate,
        address _admin,
        address _artist,
        uint256 _limitPerAddress,
        address _masterContract
    ) ERC721(name, symbol) {
        transferOwnership(_admin);
        baseURI = URI;
        blockStart = startDate;

        artist = _artist;
        maxMintAmount = _limitPerAddress;

        MAX_SUPPLY = initialSupply;    
        masterContract = _masterContract;    
    }

    // return admin
    function getAdmin() public view returns (address)  {
        return owner();
    }

    // return artist
    function getArtist() public view returns (address)  {
        return artist;
    }

    // set master contract address
    function setMaster(address _masterAddress) public onlyContract {
        masterContract = _masterAddress;
    }

    //block start
    function setBlockStart(uint256 startDate) onlyContract public {
        require(block.timestamp <= blockStart, "Sale has already started.");
        blockStart = startDate;
    }

    function getBlockStart() public view returns (uint256)  {
        return blockStart;
    }

    //supply
    function getMaxSupply() public view returns (uint256)  {
        return MAX_SUPPLY;
    }

    function getTotalSupply() public view returns (uint256)  {
        return mintedAmount;
    }

    function setMaxSupply(uint256 supply) onlyContract public {
        MAX_SUPPLY = supply;
    }

    function setMaxMintAmount(uint256 _newmaxMintAmount) onlyContract public {
        maxMintAmount = _newmaxMintAmount;
    }

    function getMaxMintAmount() public view returns (uint256) {
        return maxMintAmount;
    }

    //mint
    function mint(address _to) public onlyContract returns (uint256)  {
        require(block.timestamp >= blockStart, "Exception: Mint has not started yet so you can't get a price yet.");
        require(mintedAmount < MAX_SUPPLY, "Exception: All was minted.");
        require(mintable, "Exception: This is not mintable.");
        require(mintedPerAddress[_to] < maxMintAmount, "Exception: Reached the limit for each user. You can't mint no more");

        uint256 tokenIdToBe = getRandomness(_to);
        _safeMint(_to, tokenIdToBe);
        mintedAmount = SafeMath.add(mintedAmount, 1);
        mintedPerAddress[_to] = SafeMath.add(mintedPerAddress[_to], 1);
        isTokenIdExisting[tokenIdToBe] = true;
        
        emit SubCollectionBought(_to, tokenIdToBe);
        return tokenIdToBe;
    }
    
    function canMint(bool mintFlag) onlyContract public {
        mintable = mintFlag;
    }
    
    //base uri
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function getBaseURI() public view returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory _newBaseURI) onlyContract public {
        baseURI = _newBaseURI;
    }

    function setMetaDataExt(string memory _newExt) onlyContract public {
        metaDataExt = _newExt;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), metaDataExt))
            : "";
    }

    // randomness
    function getRandomness(address _to) public view returns (uint256) {
        uint256[] memory enabledIds = new uint256[](MAX_SUPPLY);
        uint256 count = 0;
        for(uint256 i=0; i<MAX_SUPPLY; i++ ) {
            if(!isTokenIdExisting[i]) {
                enabledIds[count] = i;
                count++;
            }
        }
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.number, block.timestamp, _to, mintedAmount))) % count;
        return enabledIds[randomNumber];
    }
}