// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// This is an NFT for Dusko https://twitter.com/duskoworld
// Smart contract developed by Ian Cherkowski https://twitter.com/IanCherkowski
// Thanks to chiru-labs for their gas friendly ERC721A implementation.
//

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";
import "./MerkleProof.sol";

contract Prochoice is
    ERC721A,
    ReentrancyGuard,
    Ownable,
    ERC2981
{
    event PaymentReceived(address from, uint256 amount);

    string private constant _name = "Pro Choice NFT";
    string private constant _symbol = "PRO";
    string public baseURI = "https://ipfs.io/ipfs/QmPnbNRjn4bSL7rsuiX8hAvkwd8CKjB7jZYzcvRXNuDTWk/";
    uint256 public cost = 0.0165 ether;
    uint256 public maxSupply = 5000;
    bool public freezeURI = false;
    bool public freezeSupply = false;
	bool public paused = true;
    bool public presale = true;
    mapping(uint256 => bool) public tokenToIsStaked;
    mapping(address => bool) private hasMinted;
    bytes32 private whitelistMerkleRoot;

    address[] private firstPayees = [msg.sender];
    uint16[] private firstShares = [100];

    constructor() ERC721A(_name, _symbol) payable {
        _setDefaultRoyalty(address(this), 500);
    }

    // @dev needed to enable receiving to test withdrawls
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    //to check if the address is an nft
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

	// @dev owner can mint to a list of addresses with the quantity entered
	function gift(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        uint256 numTokens = 0;
        uint256 i;
        
        require(recipients.length == amounts.length, "Prochoice: The number of addresses is not matching the number of amounts");

        unchecked{
            //find total to be minted
            for (i = 0; i < recipients.length; i++) {
                require(Address.isContract(recipients[i]) == false, "Prochoice: no contracts");
                numTokens += amounts[i];
            }

            require(totalSupply() + numTokens <= maxSupply, "Prochoice: Can't mint more than the max supply");

            //mint to the list
            for (i = 0; i < amounts.length; i++) {
                _safeMint(recipients[i], amounts[i]);
            }
        }
	}

    // @dev public minting, accepts affiliate address
	function mint(bytes32[] calldata merkleProof) external payable nonReentrant {
        bool approved;

        require(Address.isContract(msg.sender) == false, "Prochoice: no contracts");
        require(paused == false, "Prochoice: Minting not started yet");
        require(hasMinted[msg.sender] == false, "Prochoice: this wallet has already minted");
        require(totalSupply() + 1 <= maxSupply, "Prochoice: Can't mint more than max supply");

        if (presale) {
            approved = isValidMerkleProof(msg.sender, merkleProof);
            require(approved || msg.value >= cost, "Prochoice: You must register on heymint or pay for the nft");
        } else {
            require(msg.value >= cost, "Prochoice: You must pay for the nft");
        }

        _safeMint(msg.sender, 1);
        hasMinted[msg.sender] = true;
	}

    function isValidMerkleProof(address to, bytes32[] calldata merkleProof) public view returns (bool) {
        return MerkleProof.verify(merkleProof, whitelistMerkleRoot, keccak256(abi.encodePacked(to)));
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    //@dev prevent transfer or burn of staked id
    function _beforeTokenTransfers(address /*from*/, address /*to*/, uint256 startTokenId, uint256 /*quantity*/) internal virtual override {
        require(tokenToIsStaked[startTokenId] == false, "Prochoice, cannot transfer - currently locked");
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
		
    // @dev unpause main minting stage
	function setPaused(bool _status) external onlyOwner {
    	paused = _status;
	}
	
    // @dev unpause main minting stage
	function setPresale(bool _status) external onlyOwner {
    	presale = _status;
	}

    // @dev Set the base url path to the metadata used by opensea
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        require(freezeURI == false, "Prochoice: uri is frozen");
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

    // @dev Add payee for payment splitter
    function FreezeSupply() external onlyOwner {
        freezeSupply = true;
    }

    //reduce max supply if needed
    function reduceMaxSupply(uint16 newMax) external onlyOwner {
        require(freezeSupply == false, "Prochoice: Max supply is frozen");
        require(newMax < maxSupply, "Prochoice: New maximum must be less than existing maximum");
        require(newMax >= totalSupply(), "Prochoice: New maximum can't be less than minted count");
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