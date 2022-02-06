// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Supply.sol";
import "./Strings.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract CryptoMofayas is ERC1155, Ownable, ERC1155Supply, ReentrancyGuard {

    event PaymentReceived(address from, uint256 amount);

    string public constant name = "CryptoMofayas";
    string private constant symbol = "CMS";
    uint256 private constant _id = 1;

    string public baseURI = "https://ipfs.io/ipfs/QmSXmx7vjq6AT8HjGikLD146eKDfxW5i8L6wUun815pxNR/";
    uint256 public maxMint = 20;
    uint256 public presaleLimit = 100;
    uint256 public mintPrice = 0.05 ether;
    uint256 public maxSupply = 1999;
	bool public status = false;
	bool public presale = false;

    constructor() ERC1155(baseURI) payable {}

    // @dev needed to enable receiving to test withdrawls
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

	// @dev admin can mint to a list of addresses with the quantity entered
	function gift(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        uint256 numTokens;
        uint256 i;

        require(recipients.length == amounts.length, 
            "CryptoMofayas: The number of addresses is not matching the number of amounts");

        //find total to be minted
        numTokens = 0;
        for (i = 0; i < recipients.length; i++) {
            numTokens += amounts[i];
        }

        require(totalSupply(_id) + numTokens <= maxSupply, "CryptoMofayas: Can't mint more than the max supply");

        //mint to the list
        for (i = 0; i < numTokens; i++) {
            _mint(recipients[i], _id, amounts[i], "");
        }
	}

    // @dev public minting
    function mint(uint256 _mintAmount) external payable nonReentrant {
        uint256 supply = totalSupply(_id);

        require(msg.sender == tx.origin, "CryptoMofayas: no contracts");
        require(status || presale, "CryptoMofayas: Minting not started yet");
        require(_mintAmount > 0, "CryptoMofayas: Cant mint 0");
        require(_mintAmount <= maxMint, "CryptoMofayas: Must mint less than the max");
        require(supply + _mintAmount <= maxSupply, "CryptoMofayas: Cant mint more than max supply");
        if (presale && !status) {
            require(supply + _mintAmount <= presaleLimit, "CryptoMofayas: Presale is sold out");
        }
        require(msg.value >= mintPrice * _mintAmount, "CryptoMofayas: Must send eth of cost per nft");

        _mint(msg.sender, _id, _mintAmount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
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
        require(newMax >= totalSupply(_id), "CryptoMofayas: New maximum can't be less than minted count");
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

    function uri(uint256 _tokenId) override public view returns(string memory) {
        return string(abi.encodePacked(baseURI,Strings.toString(_tokenId),".json"));
    }
    
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override (ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}