// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Supply.sol";
import "./Strings.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract Black is ERC1155, Ownable, ERC1155Supply, ReentrancyGuard {

    event PaymentReceived(address from, uint256 amount);

    string public constant name = "Black Coin";
    string private constant symbol = "BLK";

    string public baseURI = "https://ipfs.io/ipfs/QmRXoHYKsbvW1u21NBVyG8LpPcE7feKnEZUbKwE94pWbKB/";
    uint256[] public mintPrice = [3900000000000000, 9600000000000000, 39000000000000000, 190000000000000000, 390000000000000000];
    uint256[] public maxSupply = [100000, 50000, 25000, 10000, 5000];
	bool public status = false;

    constructor() ERC1155(baseURI) payable {
    }

    // @dev needed to enable receiving to test withdrawls
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

	// @dev admin can mint to a list of addresses with the quantity entered
	function gift(address[] calldata recipients, uint256[] calldata amounts, uint256 id) external onlyOwner {
        uint256 numTokens;
        uint256 i;

        require(id <= maxSupply.length, "Black: max supply not defined for that id");
        require(recipients.length > 0, "Black: missing recipients");
        require(recipients.length == amounts.length, 
            "Black: The number of addresses is not matching the number of amounts");

        //find total to be minted
        for (i = 0; i < recipients.length; i++) {
            numTokens += amounts[i];
            require(recipients[i] != address(0), "Black: missing address");
        }

        require(totalSupply(id) + numTokens <= maxSupply[id], "Black: Can't mint more than the max supply");

        //mint to the list
        for (i = 0; i < recipients.length; i++) {
            _mint(recipients[i], id, amounts[i], "");
        }
	}

    // @dev public minting
    function mint(uint256 _mintAmount, uint256 id) external payable nonReentrant {
        uint256 supply = totalSupply(id);

        require(msg.sender == tx.origin, "Black: no contracts");
        require(status, "Black: Minting not started yet");
        require(_mintAmount > 0, "Black: Cant mint 0");
        require(id <= maxSupply.length, "Black: max supply not defined for that id");
        require(supply + _mintAmount <= maxSupply[id], "Black: Cant mint more than max supply");
        require(msg.value >= mintPrice[id] * _mintAmount, "Black: Must send eth of cost per nft");

        _mint(msg.sender, id, _mintAmount, "");
    }
    
    // @dev set cost of minting
	function setMintPrice(uint256 _newmintPrice, uint256 id) external onlyOwner {
        require(id <= maxSupply.length, "Black: max supply not defined for that id");
    	mintPrice[id] = _newmintPrice;
	}
		
    // @dev unpause main minting stage
	function setSaleStatus(bool _status) external onlyOwner {
    	status = _status;
	}
	
    // @dev Set the base url path to the metadata used by opensea
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    // @dev used to reduce the max supply instead of a burn
    function reduceMaxSupply(uint256 newMax, uint256 id) external onlyOwner {
        require(id <= maxSupply.length, "Black: max supply not defined for that id");
        require(newMax < maxSupply[id], "Black: New maximum must be less than existing maximum");
        require(newMax >= totalSupply(id), "Black: New maximum can't be less than minted count");
        maxSupply[id] = newMax;
    }

    // @dev used to withdraw erc20 tokens like DAI
    function withdrawERC20(IERC20 token, address to) external onlyOwner {
        token.transfer(to, token.balanceOf(address(this)));
    }

    // @dev used to withdraw eth
    function withdraw(address payable to) external onlyOwner {
        Address.sendValue(to,address(this).balance);
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