// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// This is an NFT for Wise Owl Club https://wiseowlclub.io/
// smart contract developed by Ian Cherkowski https://twitter.com/IanCherkowski
// Thanks to chiru-labs for their gas friendly ERC721A implementation.
//

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract WiseOwlClub is
    ERC721A,
    ReentrancyGuard,
    Ownable
{
    event PaymentReceived(address from, uint256 amount);

    string private constant _name = "Wise Owl Club";
    string private constant _symbol = "WOC";

    string public baseURI = "https://ipfs.io/ipfs/QmSaXe9nBBaEmXwBDVLXYQwQq2iWVGoXSPvV8VgKfi73xk/";
    uint256 public maxMint = 20;
    uint256 public presaleLimit = 500;
    uint256 public presalePrice = 0.08 ether;
    uint256 public mintPrice = 0.1 ether;
    uint256 public maxSupply = 3500;
    uint256 public presaleStart = 14315634;
    uint256 public mainStart = 14316447;
	mapping(address => uint8) public presaleList;
    uint16 public presaleCount;

    constructor() ERC721A(_name, _symbol) payable {
    }

    // @dev needed to enable receiving to test withdrawls
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

	// @dev admin can mint to a list of addresses with the quantity entered
	function gift(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        uint256 numTokens;
        uint256 i;

        require(recipients.length == amounts.length, 
            "Wise: The number of addresses is not matching the number of amounts");

        //find total to be minted
        numTokens = 0;
        for (i = 0; i < recipients.length; i++) {
            numTokens += amounts[i];
        }

        require(numTokens < 200, "Wise: Minting more than 200 may get stuck");
        require(totalSupply() + numTokens <= maxSupply, "Wise: Can't mint more than the max supply");

        //mint to the list
        for (i = 0; i < amounts.length; i++) {
            _safeMint(recipients[i], amounts[i]);
        }
	}

    // @dev public minting
	function mint(uint8 _mintAmount) external payable nonReentrant {
        uint256 supply = totalSupply();

        require(msg.sender == tx.origin, "Wise: no contracts");
        require(block.number > presaleStart, "Wise: Minting not started yet");
        require(_mintAmount > 0, "Wise: Cant mint 0");
        require(_mintAmount <= maxMint, "Wise: Must mint less than the max");
        require(supply + _mintAmount <= maxSupply, "Wise: Cant mint more than max supply");

        if (block.number < mainStart) {
            require(supply + _mintAmount <= presaleLimit, "Wise: Presale is sold out");

            uint8 reserve = presaleList[msg.sender];
            require(reserve > 0, "Wise: None left for you");
            require(_mintAmount <= reserve, "Wise: Cant mint more than your allocation");
            require(msg.value >= presalePrice * _mintAmount, "Wise: Must send eth of cost per nft");

            presaleList[msg.sender] = reserve - _mintAmount;
        } else {
            require(msg.value >= mintPrice * _mintAmount, "Wise: Must send eth of cost per nft");
        }
 
        _safeMint(msg.sender, _mintAmount);
	}

	// @dev record addresses of presale list
	function presaleSet(address[] calldata _addresses, uint8[] calldata _amounts) external onlyOwner {
        uint8 previous;
        require(_addresses.length == _amounts.length, 
            "Wise: The number of addresses is not matching the number of amounts");

        for(uint16 i; i < _addresses.length; i++) {
            previous = presaleList[_addresses[i]];
            presaleList[_addresses[i]] = _amounts[i];
            presaleCount = presaleCount + _amounts[i] - previous;
        }
	}

    // @dev set cost of minting
	function setMintPrice(uint256 _newmintPrice) external onlyOwner {
    	mintPrice = _newmintPrice;
	}

    // @dev set cost of presale minting	
	function setPresalePrice(uint256 _newmintPrice) external onlyOwner {
    	presalePrice = _newmintPrice;
	}

    // @dev max supply during presale
	function setPresaleLimit(uint256 _newLimit) external onlyOwner {
    	presaleLimit = _newLimit;
	}
	
    // @dev max mint amount per transaction
    function setMaxMint(uint256 _newMaxMintAmount) external onlyOwner {
	    maxMint = _newMaxMintAmount;
	}

    // @dev main minting start block
	function setMainStart(uint256 _start) external onlyOwner {
    	mainStart = _start;
	}
	
    // @dev presale start block
	function setPresaleStart(uint256 _start) external onlyOwner {
    	presaleStart = _start;
	}

    // @dev Set the base url path to the metadata used by opensea
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    // @dev show the baseuri
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // @dev used to withdraw erc20 tokens like DAI
    function withdrawERC20(IERC20 token, address to) external onlyOwner {
        token.transfer(to, token.balanceOf(address(this)));
    }

    // @dev used to withdraw eth
    function withdraw(address payable to) external onlyOwner {
        Address.sendValue(to,address(this).balance);
    }
}