// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";

contract LegionVentures is ERC721, Ownable {
    using Address for address;
    using Strings for uint256;
    
    // metadata
    bool public metadataLocked = false;
    string public baseURI = "";

    // supply and phases
    mapping (uint256 => uint256) public mintIndex;
    mapping (uint256 => uint256) public availSupply;

    bool public presaleEnded = false;
    bool public mintingEndedForever = false;
    bool public mintPaused = true;
    
    // price
    mapping (uint256 => uint256) public price_presale;
    mapping (uint256 => uint256) public price_mainsale;

    // presale access
    ERC1155Burnable public MintPass;

    // shareholder
    address public shareholder;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection, and by setting supply caps, mint indexes, and reserves
     */
    constructor()
        ERC721("LegionVentures", "LV")
    {
        MintPass = ERC1155Burnable(0x392147Bbf620E2222c3b3E39B530105aa3041493);
        shareholder = 0x5BdC0943B7EC9A0891fc94058112b76C5539aC50;

        availSupply[1] = 600;
        availSupply[2] = 300;
        availSupply[3] = 200;
        availSupply[4] = 100;

        price_presale[1] = 1.5 ether;
        price_presale[2] = 3 ether;
        price_presale[3] = 4.5 ether;
        price_presale[4] = 8 ether;
    }
    
    /**
     * ------------ METADATA ------------ 
     */

    /**
     * @dev Gets base metadata URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    /**
     * @dev Sets base metadata URI, callable by owner
     */
    function setBaseUri(string memory _uri) external onlyOwner {
        require(metadataLocked == false);
        baseURI = _uri;
    }
    
    /**
     * @dev Lock metadata URI forever, callable by owner
     */
    function lockMetadata() external onlyOwner {
        require(metadataLocked == false);
        metadataLocked = true;
    }
    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        
        string memory base = _baseURI();
        return string(abi.encodePacked(base, tokenId.toString()));
    }
    
    /**
     * ------------ SALE AND PRESALE ------------ 
     */
     
    /**
     * @dev Ends public sale forever, callable by owner
     */
    function endSaleForever() external onlyOwner {
        mintingEndedForever = true;
    }
    
    /**
     * @dev Ends the presale, callable by owner
     */
    function endPresale() external onlyOwner {
        presaleEnded = true;
    }

    /**
     * @dev Pause/unpause sale or presale
     */
    function togglePauseMinting() external onlyOwner {
        mintPaused = !mintPaused;
    }

    /**
     * ------------ CONFIGURATION ------------ 
     */

    /**
     * @dev Set presale access token address
     */
    function setMintPass(address addr) external onlyOwner {
        MintPass = ERC1155Burnable(addr);
    }

    /**
     * @dev Set presale prices
     */
    function setConfig(uint256[] calldata _types, uint256[] calldata _presalePrices, uint256[] calldata _mainsalePrices, uint256[] calldata _supply) external onlyOwner {
        for (uint256 i = 0; i < _types.length; i++) {
            price_presale[_types[i]] = _presalePrices[i];
            price_mainsale[_types[i]] = _mainsalePrices[i];
            availSupply[_types[i]] = _supply[i];
        }
    }

    /**
     * ------------ MINTING ------------ 
     */
    
    /**
     * @dev Mints `count` tokens to `to` address; internal
     */
    function mintInternal(address to, uint256 count, uint256 mtype) internal {
        for (uint256 i = 0; i < count; i++) {
            _mint(to, mintIndex[mtype] + mtype*1000-1000);
            mintIndex[mtype]++;
        }
    }

    /**
     * @dev Owner minting
     */
    function mintOwner(uint256 mtype, address[] calldata addresses) public onlyOwner {
        require(mintingEndedForever == false, "Sale ended");
        require(mintIndex[mtype] + addresses.length <= availSupply[mtype], "Supply exceeded");

        for (uint256 i = 0; i < addresses.length; i++) {        
            mintInternal(addresses[i], 1, mtype);
        }
    }

    /**
     * @dev Owner minting - advanced
     */
    function mintOwnerAdvanced(uint256[] calldata mtypes, uint256[] calldata counts, address[] calldata addresses) public onlyOwner {
        require(mintingEndedForever == false, "Sale ended");

        for (uint256 i = 0; i < addresses.length; i++) {
            require(mintIndex[mtypes[i]] + counts[i] <= availSupply[mtypes[i]], "Supply exceeded");
            mintInternal(addresses[i], counts[i], mtypes[i]);
        }
    }
    
    /**
     * @dev Public minting during public sale or presale
     */
    function mint(uint256 count, uint256 mtype) public payable{
        require(count > 0, "Count can't be 0");
        require(!mintPaused, "Minting is currently paused");
        require(mintingEndedForever == false, "Sale ended");
        require(mintIndex[mtype] + count <= availSupply[mtype], "Supply exceeded");

        if (!presaleEnded) {
            // presale checks
            uint256 mintPassBalance = MintPass.balanceOf(msg.sender, mtype);
            require(count <= mintPassBalance, "Count too high");
            require(msg.value == count * price_presale[mtype], "Ether value incorrect");

            MintPass.burn(msg.sender, mtype, count);
        } else {
            require(count == 1, "Limit exceeded");
            uint256 price;
            if (price_mainsale[mtype] != 0) {
                price = price_mainsale[mtype];
            } else {
                price = price_presale[mtype];
            }
            require(msg.value == count * price, "Ether value incorrect");
        }
        
        mintInternal(msg.sender, count, mtype);
    }

    /**
     * @dev Withdraw ether from this contract, callable by owner
     */
    function withdraw() external {
        require(msg.sender == owner() || msg.sender == shareholder, "Unauthorized");

        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance*93/100);
        payable(shareholder).transfer(balance*7/100);
    }
}