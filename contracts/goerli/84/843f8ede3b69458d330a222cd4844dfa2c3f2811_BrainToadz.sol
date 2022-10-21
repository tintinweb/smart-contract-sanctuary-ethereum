// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// This is an NFT for BrainToadz NFT https://twitter.com/braintoadznft
//

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";

contract BrainToadz is
    ERC721A,
    ReentrancyGuard,
    Ownable,
    ERC2981
{

    bool public presaleOpen = false;
    bool public publicOpen = false;
    bool public freezeURI = false;
    bool public reveal = false;
    string private constant _name = "BRAINTOADZ";
    string private constant _symbol = "TOADZ";
    string public baseURI = "ipfs://QmSeWHPabgbpSneeWxDsbVrzvp493THttFT52dVR6HDUjq";
    uint16 public maxSupply = 3333;
    uint16 public maxMint = 7;
    uint256 public preCost = 0.069 ether;
    uint256 public saleCost = 0.0777 ether;
    bytes32 private whitelistMerkleRoot;
	mapping(address => uint16) private minted;

    event PaymentReceived(address from, uint256 amount);

    constructor() ERC721A(_name, _symbol) payable {
        _setDefaultRoyalty(address(this), 500);
    }

    //enable payments to be received from airdrops
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    // @dev public minting
	function mint(uint16 mintAmount, bytes32[] calldata merkleProof) external payable nonReentrant {
        bool approved;

        require(Address.isContract(msg.sender) == false, "BrainToadz: no contracts");
        require(totalSupply() + mintAmount <= maxSupply, "BrainToadz: Can't mint more than max supply");

        if (msg.sender == owner()) {
            //unrestricted

        } else if (presaleOpen && !publicOpen) {
            approved = isValidMerkleProof(msg.sender, merkleProof);
            require(approved, "BrainToadz: You are not on the presale list");
            require(mintAmount + minted[msg.sender] <= maxMint, "BrainToadz: Must mint less than this quantity");
            require(msg.value >= preCost * mintAmount, "BrainToadz: You must pay for the nft");

        } else if (publicOpen) {
            require(mintAmount + minted[msg.sender] <= maxMint, "BrainToadz: Must mint less than this quantity");
            require(msg.value >= saleCost * mintAmount, "BrainToadz: You must pay for the nft");

        } else {
            require(false, "BrainToadz: minting is not open yet");
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

    // @dev max mint amount for paid nft
    function setMaxMint(uint16 _newMax) external onlyOwner {
	    maxMint = _newMax;
	}

    // @dev set cost of minting
	function setSaleCost(uint256 _newCost) external onlyOwner {
    	saleCost = _newCost;
	}
			
    // @dev set cost of minting
	function setPreCost(uint256 _newCost) external onlyOwner {
    	preCost = _newCost;
	}

    function cost() external view returns (uint256) {
        uint256 mintCost;
        if (publicOpen) {
            mintCost = saleCost;
        } else {
            mintCost = preCost;
        }
        return mintCost;
    }

    // @dev allow anyone to mint
	function setPublicOpen(bool _status) external onlyOwner {
    	publicOpen = _status;
	}

    // @dev allow Moonbird owners to mint
	function setPresaleOpen(bool _status) external onlyOwner {
    	presaleOpen = _status;
	}

    // @dev Set the base url path to the metadata used by opensea
    function setBaseURI(string memory _baseTokenURI, bool setReveal) external onlyOwner {
        require(freezeURI == false, "BrainToadz: uri is frozen");
        baseURI = _baseTokenURI;
        reveal = setReveal;
    }

    // @dev freeze the URI
    function setFreezeURI() external onlyOwner {
        freezeURI = true;
    }

    // @dev show the baseuri
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        //string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 
                ? reveal 
                    ? 
                    string(abi.encodePacked(baseURI, _toString(tokenId),".json")) 
                    : baseURI 
                : '';
    }

    //reduce max supply if needed
    function reduceMaxSupply(uint16 newMax) external onlyOwner {
        require(newMax < maxSupply, "BrainToadz: New maximum must be less than existing maximum");
        require(newMax >= totalSupply(), "BrainToadz: New maximum can't be less than minted count");
        maxSupply = newMax;
    }

    //to support royalties
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    //set royalties
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    //withdraw eth
    function withdraw() external onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    //withdraw erc20
    function withdrawToken(IERC20 token) external onlyOwner {
        SafeERC20.safeTransfer(token, payable(owner()), token.balanceOf(address(this)));
    }
}