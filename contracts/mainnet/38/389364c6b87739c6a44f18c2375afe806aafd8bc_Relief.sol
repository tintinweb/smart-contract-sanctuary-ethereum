// SPDX-License-Identifier: MIT
// This is an NFT to raise funds for Ukraine.
// All funds are being sent to https://www.comebackalive.in.ua/
// Smart contract developed by Ian Cherkowski https://twitter.com/IanCherkowski

pragma solidity ^0.8.12;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Supply.sol";
import "./Strings.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract Relief is ERC1155, Ownable, ERC1155Supply, ReentrancyGuard {

    event PaymentReceived(address from, uint256 amount);

    string public constant name = "Ukraine Relief";
    string private constant symbol = "UAR";

    string public baseURI = "https://ipfs.io/ipfs/QmPnbNRjn4bSL7rsuiX8hAvkwd8CKjB7jZYzcvRXNuDTWk/";
    uint256 public maxMint = 20;
    uint256 public mintPrice = 0.05 ether;
    uint256 public maxSupply = 10000;
    uint256 private id = 0;

    constructor() ERC1155(baseURI) payable {
    }

    // @dev needed to enable receiving to test withdrawls
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    // @dev public minting
    function mint(uint256 _mintAmount) external payable nonReentrant {
        uint256 supply = totalSupply(id);

        require(msg.sender == tx.origin, "Relief: no contracts");
        require(_mintAmount > 0, "Relief: Cant mint 0");
        require(_mintAmount <= maxMint, "Relief: Must mint less than the max");
        require(supply + _mintAmount <= maxSupply, "Relief: Cant mint more than max supply");
        require(msg.value >= mintPrice * _mintAmount, "Relief: Must send eth of cost per nft");

        _mint(msg.sender, id, _mintAmount, "");
    }
    
    // @dev set cost of minting
	function setMintPrice(uint256 _newmintPrice) external onlyOwner {
    	mintPrice = _newmintPrice;
	}
		
    // @dev max mint amount per transaction
    function setMaxMintAmount(uint256 _newMaxMintAmount) external onlyOwner {
	    maxMint = _newMaxMintAmount;
	}

    // @dev Set the base url path to the metadata used by opensea
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    // @dev used to reduce the max supply instead of a burn
    function reduceMaxSupply(uint256 newMax) external onlyOwner {
        require(newMax < maxSupply, "Relief: New maximum must be less than existing maximum");
        require(newMax >= totalSupply(id), "Relief: New maximum can't be less than minted count");
        maxSupply = newMax;
    }

    // @dev used to withdraw erc20 tokens like DAI
    function withdrawERC20(IERC20 token) external {
        //https://www.comebackalive.in.ua/
        address to = 0xa1b1bbB8070Df2450810b8eB2425D543cfCeF79b;
        token.transfer(payable(to), token.balanceOf(address(this)));
    }

    // @dev used to withdraw eth
    function withdraw() external {
        //https://www.comebackalive.in.ua/
        address to = 0xa1b1bbB8070Df2450810b8eB2425D543cfCeF79b;
        Address.sendValue(payable(to),address(this).balance);
    }

    function uri(uint256 _tokenId) override public view returns(string memory) {
        return string(abi.encodePacked(baseURI,Strings.toString(_tokenId),".json"));
    }
    
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override (ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}