// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// This is an NFT for Dusko https://twitter.com/duskoworld
// Smart contract developed by Ian Cherkowski https://twitter.com/IanCherkowski
// Thanks to chiru-labs for their gas friendly ERC721A implementation.
//

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./ERC2981.sol";

contract Dusko is
    ERC721A,
    ReentrancyGuard,
    PaymentSplitter,
    Ownable,
    ERC2981
{
    string private constant _name = "Dusko";
    string private constant _symbol = "DUSKO";
    string public baseURI = "https://ipfs.io/ipfs/QmTmuozNTeBCoSdKiAo3zWo51mY62rPLyqQSea3QQiT5bR/";
    uint256 public maxMint = 3;
    uint256 public preCost = 0.15 ether;
    uint256 public mainCost = 0.2 ether;
    uint256 public maxSupply = 137;
    uint256 public presaleCount;
    bool public freezeURI = false;
    bool public freezeSupply = false;
	bool public mainSale = false;
	bool public presale = false;
	mapping(address => uint256) public presaleList;
	mapping(address => uint256) public mintList;

    address[] private firstPayees = [0xF34ddAf8984E115700AEf4EfDC5cb1Bec69785D3,0xCc81ec04591f56a730E429795729D3bD6C21D877,0xD8f9B770fe183463a1ECF45b72CBb8a460047CdB];
    uint16[] private firstShares = [10,30,60];

    constructor() ERC721A(_name, _symbol) PaymentSplitter(firstPayees, firstShares) payable {
        _setDefaultRoyalty(address(this), 500);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

	// @dev owner can mint to a list of addresses with the quantity entered
	function gift(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        uint256 numTokens = 0;
        uint256 i;
        
        require(recipients.length == amounts.length, "Dusko: The number of addresses is not matching the number of amounts");

        //find total to be minted
        for (i = 0; i < recipients.length; i++) {
            require(Address.isContract(recipients[i]) == false, "Dusko: no contracts");
            numTokens += amounts[i];
        }

        require(totalSupply() + numTokens <= maxSupply, "Dusko: Can't mint more than the max supply");

        //mint to the list
        for (i = 0; i < amounts.length; i++) {
            _safeMint(recipients[i], amounts[i]);
        }
	}

    // @dev public minting, accepts affiliate address
	function mint(uint256 _mintAmount) external payable nonReentrant {
        uint256 supply = totalSupply();

        require(Address.isContract(msg.sender) == false, "Dusko: no contracts");
        require(mainSale || presale, "Dusko: Minting not started yet");
        require(_mintAmount > 0, "Dusko: Cant mint 0");
        require(supply + _mintAmount <= maxSupply, "Dusko: Cant mint more than max supply");
        require(msg.value >= cost() * _mintAmount, "Dusko: Must send eth of cost per nft");
        
        if (presale && !mainSale) {
            uint256 reserve = presaleList[msg.sender];
            require(reserve > 0, "Dusko: None left for you");
            require(_mintAmount <= reserve, "Dusko: Cant mint more than your allocation");
            presaleList[msg.sender] -= _mintAmount;
        }

        require(mintList[msg.sender] + _mintAmount <= maxMint, "Dusko: Must mint less than the max");
        mintList[msg.sender] += _mintAmount;

        _safeMint(msg.sender, _mintAmount);
	}

    function cost() public view returns (uint256) {
        uint256 _cost;
        if (!mainSale) {
            _cost = preCost;
        } else {
            _cost = mainCost;
        }
        return _cost;
    }

	// @dev record addresses of presale list
	function presaleSet(address[] calldata _addresses, uint256[] calldata _amounts) external onlyOwner {
        uint256 previous;

        require(_addresses.length == _amounts.length,
            "Dusko: The number of addresses is not matching the number of amounts");

        for(uint256 i; i < _addresses.length; i++) {
            require(Address.isContract(_addresses[i]) == false, "Dusko: no contracts");

            previous = presaleList[_addresses[i]];
            presaleList[_addresses[i]] = _amounts[i];
            presaleCount = presaleCount + _amounts[i] - previous;
        }
	}

    // @dev set cost of minting
	function setMainCost(uint256 _newCost) external onlyOwner {
    	mainCost = _newCost;
	}
		
    // @dev set presale cost of minting
	function setPreCost(uint256 _newCost) external onlyOwner {
    	preCost = _newCost;
	}
		
    // @dev max mint amount per transaction
    function setMaxMint(uint256 _newMaxMintAmount) external onlyOwner {
	    maxMint = _newMaxMintAmount;
	}

    // @dev unpause main minting stage
	function setMainStatus(bool _status) external onlyOwner {
    	mainSale = _status;
	}
	
    // @dev unpause presale minting stage
	function setPresaleStatus(bool _presale) external onlyOwner {
    	presale = _presale;
	}

    // @dev Set the base url path to the metadata used by opensea
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        require(freezeURI == false, "Dusko: uri is frozen");
        baseURI = _baseTokenURI;
    }

    // @dev freeze the URI
    function setFreezeURI() external onlyOwner {
        freezeURI = true;
    }

    // @dev freeze the total supply
    function setFreezeSupply() external onlyOwner {
        freezeSupply = true;
    }

    // @dev show the baseuri
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // @dev used to reduce the max supply instead of a burn
    function setMaxSupply(uint256 newMax) external onlyOwner {
        require(freezeSupply == false, "Dusko: Total supply is locked");
        require(newMax >= totalSupply(), "Dusko: New maximum can't be less than minted count");
        maxSupply = newMax;
    }

    // @dev Add payee for payment splitter
    function addPayee(address account, uint16 shares_) external onlyOwner {
        _addPayee(account, shares_);
    }

    // @dev Set the number of shares for payment splitter
    function setShares(address account, uint16 shares_) external onlyOwner {
        _setShares(account, shares_);
    }

    // @dev add tokens that are used by payment splitter
    function addToken(address account) external onlyOwner {
        _addToken(account);
    }

    // @dev release payments for minting to one payee
    function release(address payable account) external nonReentrant {
        require(Address.isContract(account) == false, "Dusko: no contracts");
        _release(account);
    }

    // @dev release ERC20 tokens due to a payee
    function releaseToken(IERC20 token, address payable account) external nonReentrant {
        require(Address.isContract(account) == false, "Dusko: no contracts");
        _releaseToken(token, account);
    }

    // @dev anyone can run withdraw which will send all payments for minting
    function withdraw() external nonReentrant {
        _withdraw();
    }

    /**
     * @dev External onlyOwner version of {ERC2981-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}