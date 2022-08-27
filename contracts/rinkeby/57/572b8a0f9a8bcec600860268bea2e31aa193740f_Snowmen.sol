// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

//import "./APileOfSnow.sol";
import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface APileOfSnow {
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
    function melt(uint256 tokenId) external;
}

contract Snowmen is ERC721AQueryable, Ownable, ReentrancyGuard {
    uint256 public maxSupply = 2000;
    uint256 public tokensNeeded = 3;
    uint256 public minTokenNeeded = 2;
    uint256 public basePrice = 0.0025 ether;

    bool private mintOpen = false;

    string internal baseTokenURI = "";

    APileOfSnow private immutable APileOfSnowContract;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
    
    constructor(address _APileOfSnowAddress) ERC721A("Snowmen", "Snowmen") {
        APileOfSnowContract = APileOfSnow(_APileOfSnowAddress);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function toggleMint() external onlyOwner {
        mintOpen = !mintOpen;
    }

    function setBasePrice(uint newBasePrice) external onlyOwner {
        basePrice = newBasePrice;
    }

    function setMinTokenNeeded(uint newMinTokenNeeded) external onlyOwner {
        minTokenNeeded = newMinTokenNeeded;
    }

    function setMaxSupply(uint newSupply) external onlyOwner {
        maxSupply = newSupply;
    }

    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function mintAdmin(address to, uint qty) external onlyOwner {
        _mintTo(to, qty);
    }

    function mint() external payable  callerIsUser nonReentrant {
        require(mintOpen, "Sale not active");
        _mintCheck();
    }

    function _mintCheck() internal {
        uint256 totalOwned = APileOfSnowContract.balanceOf(_msgSender());
        
        require(totalOwned >= minTokenNeeded, "Not enough piles, need at least 2.");
        require(1 + totalSupply() < maxSupply, "Exceeds Total Supply");

        require(msg.value >= getPayableAmount(_msgSender()), "Incorrect ETH amount");

        uint256 maxBurn = (totalOwned >= tokensNeeded ? tokensNeeded : totalOwned);
        uint256 burnQty = (maxBurn >= minTokenNeeded ? maxBurn : minTokenNeeded);

        if (burnQty > 0) {
            uint256[] memory tokens;
            tokens = APileOfSnowContract.tokensOfOwner(_msgSender());
            for (uint256 i = 0; i < tokens.length && i < burnQty; i++) {
                APileOfSnowContract.melt(tokens[i]);
            }
        }
        _mintTo(_msgSender(), 1);
    }

    function getPayableAmount(address _wallet) public view returns (uint256)
    {
        uint256 totalOwned = APileOfSnowContract.balanceOf(_wallet);
        uint256 maxBuy = (totalOwned < minTokenNeeded ? 0 : (totalOwned > tokensNeeded ? 0 : tokensNeeded - (totalOwned > minTokenNeeded ? totalOwned : minTokenNeeded)));

        return maxBuy * basePrice;
    }

    function _mintTo(address to, uint qty) internal {
        require(qty + totalSupply() < maxSupply, "Exceeds Total Supply");
        _mint(to, qty);
    }
	
    function totalBurned() external view returns (uint256) {
        return _totalBurned();
    }
	
    function mintedBySender() external view returns (uint256) {
        return _numberMinted(_msgSender());
    }
	
    function burnedByOwner(address owner) external view returns (uint256) {
        return _numberBurned(owner);
    }
    
	function melt(uint256 tokenId) external {
        _burn(tokenId, true);
	}

    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
}