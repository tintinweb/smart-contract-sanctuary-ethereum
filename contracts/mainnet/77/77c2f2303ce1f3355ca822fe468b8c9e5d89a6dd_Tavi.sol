// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// This is an NFT for Tavi https://twitter.com/
// Smart contract developed by Ian Cherkowski https://twitter.com/IanCherkowski
//

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./ERC2981.sol";

contract Tavi is
    ERC721A,
    ReentrancyGuard,
    PaymentSplitter,
    Ownable,
    ERC2981
{
    string private constant _name = "Tavi";
    string private constant _symbol = "TAVI";
    string public baseURI = "https://ipfs.io/ipfs/QmPnbNRjn4bSL7rsuiX8hAvkwd8CKjB7jZYzcvRXNuDTWk/";
    uint256 public maxMint = 20;
    uint256 public cost = 0.09 ether;
    uint256 public maxSupply = 5000;
    bool public freezeURI = false;
    bool public freezeSupply = false;
	bool public paused = true;
    mapping(uint256 => bool) private tokenToIsStaked;

    address[] private firstPayees = [0xC740B55610D064F74FE16dbD60DE25da0858D973, 0x8451675BBb43B7a9eA9FC5436AD5fe6474222511, 0x28C2F904BA8e26f8D1638d71455FC0a114d72047];
    uint16[] private firstShares = [50, 40, 10];

    constructor() ERC721A(_name, _symbol) PaymentSplitter(firstPayees, firstShares) payable {
        _setDefaultRoyalty(address(this), 500);
    }

    //added so that code support royalties
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

	// @dev owner can mint to a list of addresses with the quantity entered
	function gift(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        uint256 numTokens = 0;
        uint256 i;
        
        require(recipients.length == amounts.length, "Color: The number of addresses is not matching the number of amounts");

        unchecked{
            //find total to be minted
            for (i = 0; i < recipients.length; i++) {
                require(Address.isContract(recipients[i]) == false, "Color: no contracts");
                numTokens += amounts[i];
            }

            require(totalSupply() + numTokens <= maxSupply, "Color: Can't mint more than the max supply");

            //mint to the list
            for (i = 0; i < amounts.length; i++) {
                _safeMint(recipients[i], amounts[i]);
            }
        }
	}

    // @dev public minting
	function mint(address _to, uint256 _mintAmount) external payable nonReentrant {
        uint256 supply = totalSupply();

        require(Address.isContract(msg.sender) == false, "Color: no contracts");
        require(Address.isContract(_to) == false, "Color: no contracts");
        require(paused == false, "Color: Minting not started yet");
        require(_mintAmount > 0, "Color: Cant mint 0");
        require(_mintAmount <= maxMint, "Color: Must mint less than the max");
        require(supply + _mintAmount <= maxSupply, "Color: Cant mint more than max supply");
        require(msg.value >= cost * _mintAmount, "Color: Must send eth of cost per nft");
        
        _safeMint(_to, _mintAmount);
	}

    //@dev prevent transfer of staked id
    function _beforeTokenTransfers(address /*from*/, address /*to*/, uint256 startTokenId, uint256 /*quantity*/) internal virtual override {
        require(tokenToIsStaked[startTokenId] == false, "Color: Cannot transfer - currently locked");
    }

    /**
     *  @dev returns whether a token is currently staked
     */
    function isStaked(uint256 tokenId) public view returns (bool) {
        return tokenToIsStaked[tokenId];
    }

    /**
     *  @dev marks a token as staked, calling this function
     *  you disable the ability to transfer the token.
     */
    function stake(uint256 tokenId) external nonReentrant {
        require(msg.sender == ownerOf(tokenId), "Color: caller is not the owner");
        tokenToIsStaked[tokenId] = true;
    }

    /**
     *  @dev marks a token as unstaked. By calling this function
     *  you re-enable the ability to transfer the token.
     */
    function unstake(uint256 tokenId) external nonReentrant {
        require(msg.sender == ownerOf(tokenId), "Color: caller is not the owner");
        tokenToIsStaked[tokenId] = false;
    }

    // @dev set cost of minting
	function setCost(uint256 _newCost) external onlyOwner {
    	cost = _newCost;
	}
		
    // @dev max mint amount per transaction
    function setMaxMint(uint256 _newMaxMintAmount) external onlyOwner {
	    maxMint = _newMaxMintAmount;
	}

    // @dev unpause main minting stage
	function setPaused(bool _status) external onlyOwner {
    	paused = _status;
	}
	
    // @dev Set the base url path to the metadata used by opensea
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        require(freezeURI == false, "Color: uri is frozen");
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

    // @dev freeze the total supply to be done at some point in the future
    function FreezeSupply() external onlyOwner {
        freezeSupply = true;
    }

    // @dev can be used to reduce the max supply if needed
    function reduceMaxSupply(uint16 newMax) external onlyOwner {
        require(freezeSupply == false, "Color: Max supply is frozen");
        require(newMax < maxSupply, "Color: New maximum must be less than existing maximum");
        require(newMax >= totalSupply(), "Color: New maximum can't be less than minted count");
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

    // @dev release payments to one payee
    function release(address payable account) external nonReentrant {
        require(Address.isContract(account) == false, "Color: no contracts");
        _release(account);
    }

    // @dev release ERC20 tokens due to a payee
    function releaseToken(IERC20 token, address payable account) external nonReentrant {
        require(Address.isContract(account) == false, "Color: no contracts");
        _releaseToken(token, account);
    }

    // @dev anyone can run withdraw which will send all payments
    function withdraw() external nonReentrant {
        _withdraw();
    }

    /**
     * @dev External onlyOwner version of {ERC2981-_setDefaultRoyalty}.
     * sets the receiver of royalties and the fee
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}