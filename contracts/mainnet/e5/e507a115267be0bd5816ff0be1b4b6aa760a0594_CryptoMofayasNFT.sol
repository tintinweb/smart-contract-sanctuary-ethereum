// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// This is an NFT for CryptoMofayas https://www.cryptomofayas.com/
// Smart contract developed by Ian Cherkowski https://twitter.com/IanCherkowski
// Thanks to chiru-labs for their gas friendly ERC721A implementation.
//

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract CryptoMofayasNFT is
    ERC721A,
    ReentrancyGuard,
    Ownable
{
    event PaymentReceived(address from, uint256 amount);

    string private constant _name = "CryptoMofayas";
    string private constant _symbol = "CMS";
    string public baseURI = "https://ipfs.io/ipfs/QmcZjwmDovzBU3AQP4q91pHyZ3moE1vXyAU8Tsxmcmmeyv/";
    uint256 public maxMint = 20;
    uint256 public presaleLimit = 200;
    uint256 public presalePrice = 0.09 ether;
    uint256 public mintPrice = 0.1 ether;
    uint256 public maxSupply = 1999;
    uint256 public commission = 15;
    bool public freeze = false;
	bool public status = false;
	bool public presale = false;
    bool public onlyAffiliate = true;
	mapping(address => bool) public affiliateList;

    constructor() ERC721A(_name, _symbol) payable {
    }

    // @dev needed to enable receiving to test withdrawls
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

	// @dev owner can mint to a list of addresses with the quantity entered
	function gift(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        uint256 numTokens = 0;
        uint256 i;
        
        require(recipients.length == amounts.length, "CryptoMofayas: The number of addresses is not matching the number of amounts");

        //find total to be minted
        for (i = 0; i < recipients.length; i++) {
            require(Address.isContract(recipients[i]) == false, "CryptoMofayas: no contracts");
            numTokens += amounts[i];
        }

        require(numTokens < 200, "CryptoMofayas: Minting more than 200 may get stuck");
        require(totalSupply() + numTokens <= maxSupply, "CryptoMofayas: Can't mint more than the max supply");

        //mint to the list
        for (i = 0; i < amounts.length; i++) {
            _safeMint(recipients[i], amounts[i]);
        }
	}

    // @dev public minting, accepts affiliate address
	function mint(uint256 _mintAmount, address affiliate) external payable nonReentrant {
        uint256 supply = totalSupply();

        require(Address.isContract(msg.sender) == false, "CryptoMofayas: no contracts");
        require(Address.isContract(affiliate) == false, "CryptoMofayas: no contracts");
        require(status || presale, "CryptoMofayas: Minting not started yet");
        require(_mintAmount > 0, "CryptoMofayas: Cant mint 0");
        require(_mintAmount <= maxMint, "CryptoMofayas: Must mint less than the max");
        require(supply + _mintAmount <= maxSupply, "CryptoMofayas: Cant mint more than max supply");

        if (presale && !status) {
            require(supply + _mintAmount <= presaleLimit, "CryptoMofayas: Presale is sold out");
            require(msg.value >= presalePrice * _mintAmount, "CryptoMofayas: Must send eth of cost per nft");
        } else {
            require(msg.value >= mintPrice * _mintAmount, "CryptoMofayas: Must send eth of cost per nft");
        }
        
        _safeMint(msg.sender, _mintAmount);

        //if address is owner then no payout
        if (affiliate != owner() && commission > 0) {
            //if only recorded affiliates can receive payout
            if (onlyAffiliate == false || (onlyAffiliate && affiliateList[affiliate])) {
                //pay out the affiliate
                Address.sendValue(payable(affiliate), msg.value * _mintAmount * commission / 100);
            }
        }
	}

    // @dev record affiliate address
	function allowAffiliate(address newAffiliate, bool allow) external onlyOwner {
        require(newAffiliate != address(0), "CryptoMofayas: not valid address");
        require(Address.isContract(newAffiliate) == false, "CryptoMofayas: no contracts");

        affiliateList[newAffiliate] = allow;
	}

    // @dev set commission amount in percentage
 	function setCommission(uint256 _newCommission) external onlyOwner {
        require(_newCommission < 100, "CryptoMofayas: must be percentage");
    	commission = _newCommission;
	}

    // @dev if only recorded affiliate can receive payout
	function setOnlyAffiliate(bool _affiliate) external onlyOwner {
    	onlyAffiliate = _affiliate;
	}
	
    // @dev set cost of minting
	function setMintPrice(uint256 _newmintPrice) external onlyOwner {
    	mintPrice = _newmintPrice;
	}
	
    // @dev set cost of minting
	function setPresalePrice(uint256 _newmintPrice) external onlyOwner {
    	presalePrice = _newmintPrice;
	}

    // @dev max mint during presale
	function setPresaleLimit(uint256 _newLimit) external onlyOwner {
    	presaleLimit = _newLimit;
	}
	
    // @dev max mint amount per transaction
    function setMaxMint(uint256 _newMaxMintAmount) external onlyOwner {
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
        require(freeze == false, "CryptoMofayas: uri is frozen");
        baseURI = _baseTokenURI;
    }

    // @dev freeze the URI after the reveal
    function freezeURI() external onlyOwner {
        freeze = true;
    }

    // @dev show the baseuri
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // @dev used to reduce the max supply instead of a burn
    function reduceMaxSupply(uint256 newMax) external onlyOwner {
        require(newMax < maxSupply, "CryptoMofayas: New maximum must be less than existing maximum");
        require(newMax >= totalSupply(), "CryptoMofayas: New maximum can't be less than minted count");
        maxSupply = newMax;
    }

    // @dev used to withdraw erc20 tokens like DAI
    function withdrawERC20(IERC20 token, address to) external onlyOwner {
        require(Address.isContract(to) == false, "CryptoMofayas: no contracts");
        token.transfer(payable(to), token.balanceOf(address(this)));
    }

    // @dev used to withdraw eth
    function withdraw(address payable to) external onlyOwner {
        require(Address.isContract(to) == false, "CryptoMofayas: no contracts");
        Address.sendValue(payable(to),address(this).balance);
    }
}