//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract LaunchpadNFT is ERC721AQueryable, Ownable {
    using Strings for uint256;

    string public baseURI;
    
    uint256 public LAUNCH_MAX_SUPPLY;    // max launch supply
    uint256 public LAUNCH_SUPPLY;        // current launch supply

    address public LAUNCHPAD;

    modifier onlyLaunchpad() {
        require(LAUNCHPAD != address(0), "launchpad address must set");
        require(msg.sender == LAUNCHPAD, "must call by launchpad");
        _;
    }

    function getMaxLaunchpadSupply() view public returns (uint256) {
        return LAUNCH_MAX_SUPPLY;
    }

    function getLaunchpadSupply() view public returns (uint256) {
        return LAUNCH_SUPPLY;
    }

    constructor() ERC721A("RKName4", "RK4") {
        baseURI = "https://api.bezoge.com/token/api/wpdemo/";
        LAUNCHPAD = 0xDaDD67848167558468024a757dAfe8bfB1E7aFFA;
        LAUNCH_MAX_SUPPLY = 5000;
    }

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function mintTo(address to, uint quantity) external onlyLaunchpad {
        require(to != address(0), "can't mint to empty address");
        require(quantity > 0, "quantity must greater than zero");
        require(LAUNCH_SUPPLY + quantity <= LAUNCH_MAX_SUPPLY, "max supply reached");

        _safeMint(to, quantity);
        LAUNCH_SUPPLY += quantity;
    }

    function ownerMintTo(address to,uint256 quantity) external onlyOwner  {
        _mint(to, quantity);
    }

    function ownerBurn(uint256[] memory tokenIds) external onlyOwner  {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            _burn(tokenId);
        }
    }

    function burn(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            address owner = ownerOf(tokenId);
            require(msg.sender == owner, string(abi.encodePacked(tokenId.toString()," is not your NFT")));
            _burn(tokenId);
        }
    }

}