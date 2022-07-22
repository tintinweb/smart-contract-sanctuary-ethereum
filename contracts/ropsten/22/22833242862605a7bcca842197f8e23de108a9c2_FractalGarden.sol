// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// This is an NFT for Fractal Garden NFT https://
//

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";
import "./MerkleProof.sol";
import "./PaymentSplitter.sol";

contract FractalGarden is
    ERC721A,
    ReentrancyGuard,
    PaymentSplitter,
    Ownable,
    ERC2981
{

    string private constant _name = "Fractal Garden NFT";
    string private constant _symbol = "FRAC";
    string public baseURI = "https://ipfs.io/ipfs/QmPnbNRjn4bSL7rsuiX8hAvkwd8CKjB7jZYzcvRXNuDTWk/";
    uint256 public cost = 0.03 ether;
    uint256 public maxSupply = 4181;
    uint256 public phase = 987;
    bool public freezeURI = false;
    bool public freezeSupply = false;
	bool public paused = true;
    bool public presale = true;
    bytes32 private whitelistMerkleRoot;
    mapping(uint256 => bool) public tokenToIsStaked;
    mapping(address => bool) private hasMinted;

    address[] private firstPayees = [0x9FcFD77494a0696618Fab4568ff11aCB0F0e5d9C, 0xa4D89eb5388613A9BF7ED0eaFf5fD2c05a4B34e3];
    uint16[] private firstShares = [50, 50];

    constructor() ERC721A(_name, _symbol) PaymentSplitter(firstPayees, firstShares) payable {
        _setDefaultRoyalty(address(this), 500);
    }

    //to support royalties
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

	// @dev owner can mint to a list of addresses with the quantity entered
	function gift(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        uint256 numTokens = 0;
        uint256 i;
        
        require(recipients.length == amounts.length, "Fractal: The number of addresses is not matching the number of amounts");

        unchecked{
            //find total to be minted
            for (i = 0; i < recipients.length; i++) {
                require(Address.isContract(recipients[i]) == false, "Fractal: no contracts");
                numTokens += amounts[i];
            }

            require(totalSupply() + numTokens <= maxSupply, "Fractal: Can't mint more than the max supply");

            //mint to the list
            for (i = 0; i < amounts.length; i++) {
                _safeMint(recipients[i], amounts[i]);
            }
        }
	}

    // @dev public minting, accepts affiliate address
	function mint(bytes32[] calldata merkleProof) external payable nonReentrant {
        bool approved;

        require(Address.isContract(msg.sender) == false, "Fractal: no contracts");
        require(paused == false, "Fractal: Minting not started yet");
        require(hasMinted[msg.sender] == false, "Fractal: this wallet has already minted");
        require(totalSupply() + 1 <= phase, "Fractal: this phase is sold out");
        require(totalSupply() + 1 <= maxSupply, "Fractal: Can't mint more than max supply");

        if (presale) {
            approved = isValidMerkleProof(msg.sender, merkleProof);
            require(approved || msg.value >= cost, "Fractal: You must register on heymint or pay for the nft");
        } else {
            require(msg.value >= cost, "Fractal: You must pay for the nft");
        }

        hasMinted[msg.sender] = true;

        _safeMint(msg.sender, 1);
	}

    function isValidMerkleProof(address to, bytes32[] calldata merkleProof) public view returns (bool) {
        return MerkleProof.verify(merkleProof, whitelistMerkleRoot, keccak256(abi.encodePacked(to)));
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    //@dev prevent transfer or burn of staked id
    function _beforeTokenTransfers(address /*from*/, address /*to*/, uint256 startTokenId, uint256 /*quantity*/) internal virtual override {
        require(tokenToIsStaked[startTokenId] == false, "Fractal, cannot transfer - currently locked");
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
        require(msg.sender == ownerOf(tokenId), "Fractal: caller is not the owner");
        tokenToIsStaked[tokenId] = true;
    }

    /**
     *  @dev marks a token as unstaked. By calling this function
     *  you re-enable the ability to transfer the token.
     */
    function unstake(uint256 tokenId) external nonReentrant {
        require(msg.sender == ownerOf(tokenId), "Fractal: caller is not the owner");
        tokenToIsStaked[tokenId] = false;
    }

    // @dev set cost of minting
	function setCost(uint256 _newCost) external onlyOwner {
    	cost = _newCost;
	}
		
    // @dev set cost of minting
	function setPhase(uint256 _newPhase) external onlyOwner {
    	phase = _newPhase;
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
        require(freezeURI == false, "Fractal: uri is frozen");
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
        require(freezeSupply == false, "Fractal: Max supply is frozen");
        require(newMax < maxSupply, "Fractal: New maximum must be less than existing maximum");
        require(newMax >= totalSupply(), "Fractal: New maximum can't be less than minted count");
        maxSupply = newMax;
    }

    /**
     * @dev External onlyOwner version of {ERC2981-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
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
        require(Address.isContract(account) == false, "Fractal: no contracts");
        _release(account);
    }

    // @dev release ERC20 tokens due to a payee
    function releaseToken(IERC20 token, address payable account) external nonReentrant {
        require(Address.isContract(account) == false, "Fractal: no contracts");
        _releaseToken(token, account);
    }

    // @dev anyone can run withdraw which will send all payments
    function withdraw() external nonReentrant {
        _withdraw();
    }
}