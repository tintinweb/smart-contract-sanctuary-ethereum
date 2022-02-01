// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// smart contract for Bored Ape Record Club Anthem
// https://twitter.com/boredaperc
// Thanks to Galactic and 0x420 for their gas friendly ERC721S implementation.

import "./ERC721S.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract Anthem is ERC721Sequential, ReentrancyGuard, Ownable {

    event PaymentReceived(address from, uint256 amount);

	string public baseURI = "https://ipfs.io/ipfs/QmT5xEGKtTC439i8iS93pE8CyT5ZHJHn9Qctp9Y7hxRvGa/";
    string private constant _name = "Bored Ape Record Club Anthem";
    string private constant _symbol = "BARC";

	//sale settings
	uint256 public cost = 0.05 ether;
	uint256 public maxSupply = 1000;
	uint256 public maxMint = 7;
	uint256 public maxPresale = 2;
	uint256 public wave = 100;
	bool public status = false;
	bool public presale = false;
	mapping(address => uint256) public presaleList;

	constructor() ERC721Sequential(_name, _symbol){
    }
	
    // @dev needed to enable receiving to test withdrawls
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    // public minting
	function mint(uint256 _mintAmount) public payable nonReentrant{
        uint256 s = totalMinted();
        require(status || presale, "Anthem: Minting not started yet" );
        require(_mintAmount > 0, "Anthem: Cant mint 0" );
        require(_mintAmount <= maxMint, "Anthem: Must mint less than the max" );
        require(s + _mintAmount <= maxSupply, "Anthem: Cant mint more than max supply" );
        require(s + _mintAmount <= wave, "Anthem: Cant mint more than current wave" );
        require(msg.value >= cost * _mintAmount, "Anthem: Must send eth of cost per nft");

        // presale minting to presale list of addresses
        if (presale && !status) {
            uint256 reserve = presaleList[msg.sender];
            require(reserve > 0, "Anthem: None left for you");
            require(_mintAmount <= reserve, "Anthem: Cant mint more than your allocation");
            presaleList[msg.sender] = reserve - _mintAmount;
        }

        for (uint256 i = 0; i < _mintAmount; ++i) {
            _safeMint(msg.sender);
	    }
	    delete s;
	}

	// @dev admin can mint to a list of addresses
	function gift(address[] calldata recipients) external onlyOwner {
        uint256 numTokens;

        numTokens = recipients.length;
        require(totalMinted() + numTokens <= maxSupply, "Anthem: Sold Out");

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(recipients[i]);
        }
	}

	// record addresses of presale list
	function presaleSet(address[] calldata _addresses, uint256[] calldata _amounts) public onlyOwner {
        for(uint256 i; i < _addresses.length; i++){
            require(_amounts[i] <= maxPresale, "Anthem: Over limit set");
            presaleList[_addresses[i]] = _amounts[i];
        }
	}
	
    // set cost of minting
	function setCost(uint256 _newCost) public onlyOwner {
    	cost = _newCost;
	}
	
    // minting to be sold in waves
	function setWave(uint256 _newWave) public onlyOwner {
    	wave = _newWave;
	}
	
    // max mint amount per transaction
    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
	    maxMint = _newMaxMintAmount;
	}

    // set base url of metadata
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
	    baseURI = _newBaseURI;
	}

    // unpause main minting stage
	function setSaleStatus(bool _status) public onlyOwner {
    	status = _status;
	}
	
    // unpause presale minting stage
	function setPresaleStatus(bool _presale) public onlyOwner {
    	presale = _presale;
	}

    // @dev used to withdraw erc20 tokens like DAI
    function withdrawERC20(IERC20 token, address to) external onlyOwner {
        token.transfer(to, token.balanceOf(address(this)));
    }

    // @dev used to withdraw eth
    function withdraw(address payable to) external onlyOwner {
        Address.sendValue(to,address(this).balance);
    }

    // @dev used to reduce the max supply, works like a burn
    function reduceMaxSupply(uint256 newMax) external onlyOwner {
        require(newMax < maxSupply, "Anthem: New maximum must be less than existing maximum");
        require(newMax >= totalMinted(), "Anthem: New maximum can't be less than minted count");
        maxSupply = newMax;
    }
}