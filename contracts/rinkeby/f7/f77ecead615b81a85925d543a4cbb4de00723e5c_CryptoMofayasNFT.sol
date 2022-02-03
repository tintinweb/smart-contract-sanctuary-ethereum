// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// This is an NFT for CryptoMofayas https://twitter.com/CryptoMofayas
//

import "./ERC721Enum.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract CryptoMofayasNFT is
    ERC721Enum,
    ReentrancyGuard,
    Ownable
{
    event PaymentReceived(address from, uint256 amount);

    string private constant _name = "CryptoMofayas";
    string private constant _symbol = "CMS";

    string public baseURI = "https://ipfs.io/ipfs/QmT5xEGKtTC439i8iS93pE8CyT5ZHJHn9Qctp9Y7hxRvGa/";
    uint256 public maxMint = 20;
    uint256 public presaleLimit = 100;
    uint256 public mintPrice = 0.05 ether;
    uint256 public maxSupply = 1999;
	bool public status = false;
	bool public presale = false;

    constructor() ERC721P(_name, _symbol) payable {
    }

    // @dev needed to enable receiving to test withdrawls
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

	// @dev admin can mint to a list of addresses with the quantity entered
	function gift(address[] calldata recipients) external onlyOwner {
        uint256 numTokens;
        uint256 supply = totalSupply();

        numTokens = recipients.length;
        require(totalSupply() + numTokens <= maxSupply, "CryptoMofayas: Can't mint more than the max supply");

        //mint to the list
        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(recipients[i], supply + i);
        }
	}

    // @dev public minting
	function mint(uint256 _mintAmount) external payable nonReentrant{
        uint256 supply = totalSupply();

        require(status || presale, "CryptoMofayas: Minting not started yet");
        require(_mintAmount > 0, "CryptoMofayas: Cant mint 0");
        require(_mintAmount <= maxMint, "CryptoMofayas: Must mint less than the max");
        require(supply + _mintAmount <= maxSupply, "CryptoMofayas: Cant mint more than max supply");
        if (presale && !status) {
            require(supply + _mintAmount <= presaleLimit, "CryptoMofayas: Cant mint more during presale");
        }
        require(msg.value >= mintPrice * _mintAmount, "CryptoMofayas: Must send eth of cost per nft");
 
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
	}

    // @dev set cost of minting
	function setMintPrice(uint256 _newmintPrice) external onlyOwner {
    	mintPrice = _newmintPrice;
	}
	
    // @dev max mint during presale
	function setPresaleLimit(uint256 _newLimit) external onlyOwner {
    	presaleLimit = _newLimit;
	}
	
    // @dev max mint amount per transaction
    function setMaxMintAmount(uint256 _newMaxMintAmount) external onlyOwner {
	    maxMint = _newMaxMintAmount;
	}

    // @dev unpause main minting stage
	function setSaleStatus(bool _status) external onlyOwner {
    	status = _status;
	}
	
    // @dev unpause presale minting stage
	function setPresaleStatus(bool _presale) external onlyOwner {
    	presale = _presale;
	}

    // @dev Set the base url path to the metadata used by opensea
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    // @dev used to reduce the max supply instead of a burn
    function reduceMaxSupply(uint256 newMax) external onlyOwner {
        require(newMax < maxSupply, "CryptoMofayas: New maximum must be less than existing maximum");
        require(newMax >= totalSupply(), "CryptoMofayas: New maximum can't be less than minted count");
        maxSupply = newMax;
    }

    // @dev used to withdraw erc20 tokens like DAI
    function withdrawERC20(IERC20 token, address to) external onlyOwner {
        token.transfer(to, token.balanceOf(address(this)));
    }

    // @dev used to withdraw eth
    function withdraw(address payable to) external onlyOwner {
        Address.sendValue(to,address(this).balance);
    }

	function _baseURI() internal view virtual returns (string memory) {
    	return baseURI;
	}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    	require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
	    string memory currentBaseURI = _baseURI();
    	return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), ".json")) : "";
	}
}