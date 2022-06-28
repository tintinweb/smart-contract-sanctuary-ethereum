// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// This is an NFT for Rosie Ochoa https://rosieochoa.com/
// Smart contract developed by Ian Cherkowski https://twitter.com/IanCherkowski
// Thanks to chiru-labs for their gas friendly ERC721A implementation.
//

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";

contract Nature is
    ERC721A,
    ReentrancyGuard,
    Ownable,
    ERC2981
{
    event PaymentReceived(address from, uint256 amount);

    string private constant _name = "Blossoming Nature";
    string private constant _symbol = "BN";
    string public baseURI = "https://ipfs.io/ipfs/QmP8DonWXDEMvBZLYzC84rsCMaoDhMkSVcaX6XkL73wpyD/";
    uint256 public maxMint = 20;
    uint256 public mainCost = 1 ether;
    uint256 public maxSupply = 100;
    bool public freezeURI = false;
	bool public mintPause = true;
    bool public freezeSupply = false;

    constructor() ERC721A(_name, _symbol) payable {
        _setDefaultRoyalty(address(this), 500);
    }

    // @dev needed to enable receiving to test withdrawls
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

	// @dev owner can mint to a list of addresses with the quantity entered
	function gift(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        uint256 numTokens = 0;
        uint256 i;
        
        require(recipients.length == amounts.length, "Nature: The number of addresses is not matching the number of amounts");

        unchecked{
            //find total to be minted
            for (i = 0; i < recipients.length; i++) {
                require(Address.isContract(recipients[i]) == false, "Nature: no contracts");
                numTokens += amounts[i];
            }
        
            require(totalSupply() + numTokens <= maxSupply, "Nature: Can't mint more than the max supply");

            //mint to the list
            for (i = 0; i < amounts.length; i++) {
                _safeMint(recipients[i], amounts[i]);
            }
        }
	}

    // @dev public minting
	function mint(uint256 _mintAmount) external payable nonReentrant {
        uint256 supply = totalSupply();

        require(Address.isContract(msg.sender) == false, "Nature: no contracts");
        require(!mintPause, "Nature: Minting paused");
        require(_mintAmount > 0, "Nature: Cant mint 0");
        require(_mintAmount <= maxMint, "Nature: Must mint less than the max");
        require(supply + _mintAmount <= maxSupply, "Nature: Cant mint more than max supply");
        require(msg.value >= mainCost * _mintAmount, "Nature: Must send eth of cost per nft");

        _safeMint(msg.sender, _mintAmount);
	}

    // @dev set cost of minting
	function setMainCost(uint256 _newCost) external onlyOwner {
    	mainCost = _newCost;
	}
		
    // @dev max mint amount per transaction
    function setMaxMint(uint256 _newMaxMintAmount) external onlyOwner {
	    maxMint = _newMaxMintAmount;
	}

    // @dev unpause main minting stage
	function setMintPause(bool _status) external onlyOwner {
    	mintPause = _status;
	}
		
    // @dev Set the base url path to the metadata used by opensea
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        require(freezeURI == false, "Nature: uri is frozen");
        baseURI = _baseTokenURI;
    }

    // @dev freeze the URI
    function setFreezeURI() external onlyOwner {
        freezeURI = true;
    }

    // @dev show the baseuri
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // @dev used to set the max supply
    function setMaxSupply(uint256 newMax) external onlyOwner {
        require(freezeSupply == false, "Nature: Total supply is locked");
        require(newMax >= totalSupply(), "Nature: New maximum can't be less than minted count");
        maxSupply = newMax;
    }

    /**
     * @dev External onlyOwner version of {ERC2981-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
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