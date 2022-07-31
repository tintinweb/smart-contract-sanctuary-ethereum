pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ERC2981Royalties.sol";

contract FrenzyDucks is ERC721Enumerable, Ownable, ERC2981Royalties {
    using SafeMath for uint;

    string baseURI;

    uint public MAX_FRENZYDUCKS = 7777;
    uint public constant MAX_SALE = 10;
    
    address communityAddress = 0x4f8BdB07386A319c058d5E4488c770203caD8a9b;
    address devAddress = 0xa7ED52a40d9087Ee212EC1129753B3117f15A03F;
    address frenzyducksAddress = 0xeb010B843dAb693DafEdE3B1C25242eE6a92a8dD;
    address royaltiesAddress = 0xac5acc6FFa793a4610237A5D39d81920a32BC779;

    uint public price = 10000000000000000;
    
    mapping(address => bool) private whitelisted;
    
    bool public preSaleStarted = false;
    bool public preSaleOver = false;
    bool public saleStarted = false;
    
    event FrenzyDucksMinted(uint indexed tokenId, address indexed owner);
    
    constructor(string memory name, string memory symbol, string memory baseURI_, address[] memory _addresses) ERC721(name, symbol) {
        baseURI = baseURI_;
        addWhitelistedAdresses(_addresses);
        _setRoyalties(royaltiesAddress, 1000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981Base)
        returns (bool)
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
        require(totalSupply().add(_quantity) <= MAX_FRENZYDUCKS, "Sold out.");
        require(msg.value >= price.mul(_quantity) || msg.sender == owner(), "Ether value sent is below the price.");
        
        for (uint i = 0; i < _quantity; i++) {
            mintTo(msg.sender);
        }
    }
    
    function preMint(uint _quantity) external payable  {
        require(preSaleStarted, "Presale hasn't started.");
        require(!preSaleOver, "Presale is over.");
        require(_quantity > 0, "Quantity cannot be zero.");
        require(_quantity <= MAX_SALE, "Quantity cannot be bigger than MAX_SALE.");
        require(whitelisted[msg.sender], "This address is not allowed to buy that quantity.");
        require(totalSupply().add(_quantity) <= MAX_FRENZYDUCKS, "Sold out");
        require(msg.value >= price.mul(_quantity) || msg.sender == owner(), "Ether value sent is below the price.");
        
        for (uint i = 0; i < _quantity; i++) {
            mintTo(msg.sender);
        }
    }
    
    function mintByOwner(address _to, uint256 _quantity) public onlyOwner {
        require(_quantity > 0, "Quantity cannot be zero.");
        require(_quantity <= MAX_SALE, "Quantity cannot be bigger than MAX_SALE.");
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
    
    function startSale() external onlyOwner {
        require(!saleStarted, "Sale already active.");
        
        price = 0.09 ether;
        MAX_FRENZYDUCKS = 3333;
        saleStarted = true;
        preSaleStarted = false;
        preSaleOver = true;
    }

    function pauseSale() external onlyOwner {
        require(saleStarted, "Sale is not active.");
        
        saleStarted = false;
    }
    
    function startPreSale() external onlyOwner {
        require(!preSaleOver, "Presale is over, cannot start again.");
        require(!preSaleStarted, "Presale already active.");
        price = 0.07 ether;
        MAX_FRENZYDUCKS = 1000;
        
        preSaleStarted = true;
    }

    function pausePreSale() external onlyOwner {
        require(preSaleStarted, "Presale is not active.");
        preSaleStarted = false;
    }
    
    function checkIsWhitelisted(address wlAddress) public view returns (bool) {
        return whitelisted[wlAddress];
    }
    
    function addWhitelistedAdresses(address[] memory addresses) public onlyOwner {
        require(!preSaleOver, "presale is over");
        
        for (uint i = 0; i < addresses.length; i++) {
            whitelisted[addresses[i]] = true;
        }
    }

    function withdraw() public onlyOwner {        
        uint256 balance = address(this).balance;
        payable(communityAddress).transfer( (balance * 10) / 100 );
        payable(devAddress).transfer( (balance * 75) / 1000 );
        payable(frenzyducksAddress).transfer( (balance * 725) / 1000 );
    }
}