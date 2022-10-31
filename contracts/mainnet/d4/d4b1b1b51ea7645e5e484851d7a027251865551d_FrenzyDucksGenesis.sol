pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ERC2981Royalties.sol";

interface FrenzyDucksContract {
    function burn(uint) external;
    function ownerOf(uint) external view returns(address);
}

contract FrenzyDucksGenesis is ERC721Enumerable, Ownable, ERC2981Royalties {
    using SafeMath for uint;
    string baseURI;
    uint public MAX_FRENZYDUCKS = 333;
    uint public MAX_SALE = 5;
    uint public MAX_PER_WALET = 5;
    FrenzyDucksContract private oldContract;
    
    address communityAddress = 0x6EEa57e0D7Bf99571af3DD7a1D861bA62D7665B2;
    address frenzyducksAddress = 0x30564f2D0896B00186450B0F7989D7Ae7af51975;
    address devAddress = 0xA7b5Cf34dDb26A5e8efb8a652c9C7f5aEfB160b8;
    address marketingAddress = 0x279e5f77b3b6d6e17df1749B42426c1a1c2143dA;
    uint public price = 60000000000000000;

    mapping(uint => bool) private burnedFrenzyDucks;
    mapping(uint => address) private ownersFenzyDucks;
    
    bool public saleStarted = false;
    
    event FrenzyDucksMinted(uint indexed tokenId, address indexed owner);
    
    constructor(string memory name, string memory symbol, string memory baseURI_, address _oldContract) ERC721(name, symbol) {
        baseURI = baseURI_;
        _setRoyalties(frenzyducksAddress, 875);
        _setRoyalties(devAddress, 75);
        _setRoyalties(marketingAddress, 50);
        oldContract = FrenzyDucksContract(_oldContract);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC2981Base) returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    
    function mintTo(address _to) internal {
        uint mintIndex = totalSupply().add(1);
        _safeMint(_to, mintIndex);
        emit FrenzyDucksMinted(mintIndex, _to);
    }
    
    function mint(uint _quantity) external payable  {
        require(saleStarted, "Sale hasn't started.");
        require(_quantity > 0, "Quantity cannot be zero.");
        require(_quantity <= MAX_SALE, "Quantity cannot be bigger than MAX_BUYING.");
        require(_quantity + balanceOf(msg.sender) <= MAX_PER_WALET, "Quantity cannot be bigger than MAX_PER_WALET.");
        require(totalSupply().add(_quantity) <= MAX_FRENZYDUCKS, "Sold out.");
        require(msg.value >= price.mul(_quantity) || msg.sender == owner(), "Ether value sent is below the price.");
        
        for (uint i = 0; i < _quantity; i++) {
            mintTo(msg.sender);
        }
    }

    function validate(uint256[] memory _frenzyDucks) external payable  {
        for (uint i = 0; i < 6; i++) {
            require (oldContract.ownerOf(_frenzyDucks[i]) == msg.sender, "Only the owner of NFT can burn");
            require (!burnedFrenzyDucks[_frenzyDucks[i]], "NFT already burned");
        }

        for (uint i = 0; i < 6; i++) {
            ownersFenzyDucks[_frenzyDucks[i]] = msg.sender;
        }
    }

    function claim(uint256[] memory _frenzyDucks) external payable  {

        for (uint i = 0; i < 6; i++) {
            require (ownersFenzyDucks[_frenzyDucks[i]] == msg.sender, "Only the owner of NFT can burn");
            require (!burnedFrenzyDucks[_frenzyDucks[i]], "NFT already burned");
        }

        bool[] memory valid = new bool[](6);
        for (uint i = 0; i < 6; i++) {
            burnedFrenzyDucks[_frenzyDucks[i]] = true;
            try oldContract.ownerOf(_frenzyDucks[i]) returns (address ) {
                valid[i] = false;
            } catch (bytes memory /*lowLevelData*/) {
                valid[i] = true;
            }
        }

        for (uint i = 0; i < 6; i++) {
            require (valid[i], "NFT's not burned");
        }

        for (uint i = 0; i < 6; i++) {
            burnedFrenzyDucks[_frenzyDucks[i]] = true;
        }

        mintTo(msg.sender);
    }
    
    function mintByOwner(address _to, uint256 _quantity) public onlyOwner {
        require(_quantity > 0, "Quantity cannot be zero.");
        require(totalSupply().add(_quantity) <= MAX_FRENZYDUCKS, "Sold out.");
        
        for (uint i = 0; i < _quantity; i++) {
            mintTo(_to);
        }
    }
    
    function multiMintByOwner(address[] memory _mintAddressList, uint256[] memory _quantityList) external onlyOwner {
        require (_mintAddressList.length == _quantityList.length, "The length should be same");

        for (uint256 i = 0; i < _mintAddressList.length; i += 1) {
            mintByOwner(_mintAddressList[i], _quantityList[i]);
        }
    }

    function tokensOfOwner(address _owner) public view returns(uint[] memory ) {
        uint tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            for (uint i = 0; i < tokenCount; i++) {
                result[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return result;
        }
    }
    
    function isBurned(uint tokenId) public view returns (bool) {
        return burnedFrenzyDucks[tokenId] ? true: false;
    }
    
    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }
    
    function setMaxFrenzyDucks(uint _maxFrenzyDucks) external onlyOwner {
        MAX_FRENZYDUCKS = _maxFrenzyDucks;
    }
    
    function setMaxSale(uint _maxSale, uint _maxFrenzyDucksPerWallet) external onlyOwner {
        MAX_SALE = _maxSale;
        MAX_PER_WALET = _maxFrenzyDucksPerWallet;
    }
    
    function startSale() external onlyOwner {
        require(!saleStarted, "Sale already active.");
        
        saleStarted = true;
    }

    function pauseSale() external onlyOwner {
        require(saleStarted, "Sale is not active.");
        
        saleStarted = false;
    }

    function withdraw() public onlyOwner {        
        uint256 balance = address(this).balance;
        payable(communityAddress).transfer( (balance * 5) / 100 );
        payable(marketingAddress).transfer( (balance * 5) / 100 );
        payable(devAddress).transfer( (balance * 75) / 1000 );
        payable(frenzyducksAddress).transfer( (balance * 825) / 1000 );
    }
}