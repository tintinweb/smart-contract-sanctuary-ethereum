// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// This is an NFT for Warrior NFT https://
//

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";
import "./MerkleProof.sol";
import "./PaymentSplitter.sol";
import "./MerkleProof.sol";

contract Warrior is
    ERC721A,
    ReentrancyGuard,
    PaymentSplitter,
    Ownable,
    ERC2981
{

    string private constant _name = "Warrior NFT";
    string private constant _symbol = "WAR";
    string public baseURI = "https://ipfs.io/ipfs/QmPnbNRjn4bSL7rsuiX8hAvkwd8CKjB7jZYzcvRXNuDTWk/";
    uint256 public cost = 0.03 ether;
    uint256 public costToken = 10 ether;
    uint256 public maxSupply = 5555;
    uint16[3] public maxMint = [2, 6, 3];
    bool public freezeURI = false;
    bool public freezeSupply = false;
	bool public paused = true;
    bool public presale = true;
    bytes32 private whitelistMerkleRoot;
    mapping(uint256 => bool) public tokenToIsStaked;
	mapping(address => uint16) public minted;

    address[] private firstPayees = [0x67935A1b7E18D16d55f9Cc3638Cc612aBf3ff800, 0x9FcFD77494a0696618Fab4568ff11aCB0F0e5d9C, 0x1380c8aa439AAFf8CEf5186350ce6b08a6062E90, 0xa4D89eb5388613A9BF7ED0eaFf5fD2c05a4B34e3];
    uint16[] private firstShares = [500, 166, 166, 167];

    IERC20 public stakingToken20 = IERC20(0x87ca1AFDC373A4A49aA221b706B9Bf03eb54fd08);

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
                require(Address.isContract(recipients[i]) == false, "Warrior: no contracts");
                numTokens += amounts[i];
            }

            require(totalSupply() + numTokens <= maxSupply, "Warrior: Can't mint more than the max supply");

            //mint to the list
            for (i = 0; i < amounts.length; i++) {
                _safeMint(recipients[i], amounts[i]);
            }
        }
	}

    // @dev public minting, accepts affiliate address
	function mint(uint16 mintAmount, bytes32[] calldata merkleProof, bool withToken) external payable nonReentrant {
        bool approved;

        require(Address.isContract(msg.sender) == false, "Warrior: no contracts");
        require(paused == false, "Warrior: Minting not started yet");
        require(totalSupply() + mintAmount <= maxSupply, "Warrior: Can't mint more than max supply");

        if (withToken) {
            require(mintAmount + minted[msg.sender] <= maxMint[0], "Warrior: Must mint less than this quantity");
            uint256 amount = costToken * mintAmount;
            require(stakingToken20.balanceOf(msg.sender) >= amount, "Warrior: You don't have enough token balance");
            require(stakingToken20.allowance(msg.sender, address(this)) >= amount, "Warrior: You must give allowance in the token to this NFT contract");
            stakingToken20.transferFrom(msg.sender, address(this), amount);
        } else if (presale) {
            require(mintAmount + minted[msg.sender] <= maxMint[1], "Warrior: Must mint less than this quantity");
            approved = isValidMerkleProof(msg.sender, merkleProof);
            require(approved || msg.value >= cost * mintAmount, "Warrior: You must register on heymint or pay for the nft");
        } else {
            require(mintAmount + minted[msg.sender] <= maxMint[2], "Warrior: Must mint less than this quantity");
            require(msg.value >= cost * mintAmount, "Warrior: You must pay for the nft");
        }

        minted[msg.sender] += mintAmount;
        _safeMint(msg.sender, mintAmount);
	}

    function isValidMerkleProof(address to, bytes32[] calldata merkleProof) public view returns (bool) {
        return MerkleProof.verify(merkleProof, whitelistMerkleRoot, keccak256(abi.encodePacked(to)));
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    //@dev prevent transfer or burn of staked id
    function _beforeTokenTransfers(address /*from*/, address /*to*/, uint256 startTokenId, uint256 /*quantity*/) internal virtual override {
        require(tokenToIsStaked[startTokenId] == false, "Warrior, cannot transfer - currently locked");
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
        require(msg.sender == ownerOf(tokenId), "Warrior: caller is not the owner");
        tokenToIsStaked[tokenId] = true;
    }

    /**
     *  @dev marks a token as unstaked. By calling this function
     *  you re-enable the ability to transfer the token.
     */
    function unstake(uint256 tokenId) external nonReentrant {
        require(msg.sender == ownerOf(tokenId), "Warrior: caller is not the owner");
        tokenToIsStaked[tokenId] = false;
    }

    // @dev max mint amount for paid nft
    function setMaxMint(uint16 _phase, uint16 _newMax) external onlyOwner {
	    maxMint[_phase] = _newMax;
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
        require(freezeURI == false, "Warrior: uri is frozen");
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
        require(freezeSupply == false, "Warrior: Max supply is frozen");
        require(newMax < maxSupply, "Warrior: New maximum must be less than existing maximum");
        require(newMax >= totalSupply(), "Warrior: New maximum can't be less than minted count");
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
        require(Address.isContract(account) == false, "Warrior: no contracts");
        _release(account);
    }

    // @dev release ERC20 tokens due to a payee
    function releaseToken(IERC20 token, address payable account) external nonReentrant {
        require(Address.isContract(account) == false, "Warrior: no contracts");
        _releaseToken(token, account);
    }

    // @dev anyone can run withdraw which will send all payments
    function withdraw() external nonReentrant {
        _withdraw();
    }
}