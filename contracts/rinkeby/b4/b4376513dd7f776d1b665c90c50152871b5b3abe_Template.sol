// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC2981.sol";
import "./IERC20.sol";

/**********************************************
 This is only a template to make Smart Contracts of NFTs.
 **********************************************/

contract Template is ERC721A, IERC2981, Ownable {
    bool public paused;
    string public URI;
    address public addressToBePayed;
    uint256 public constant TOTAL_SUPPLY = 10000;
    mapping(address => bool) public adressesMinted;

    constructor() ERC721A("Template", "TEMPLATE") {}

    function mint() external {
        uint256 total = _totalMinted();

        require(msg.sender == tx.origin, "Smart Contracts not allowed.");
        require(paused, "The mint isn't ready yet.");
        require(!adressesMinted[msg.sender], "You already minted.");
        require(total + 1 <= TOTAL_SUPPLY, "It exceed the total supply.");

        _mint(msg.sender, 1);
        adressesMinted[msg.sender] = true;
    }

    function mintTo(address to, uint256 ammount) external onlyOwner {
        uint256 total = _totalMinted();
        require(total + ammount <= TOTAL_SUPPLY, "It exceed the total supply.");

        _mint(to, ammount);
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    function bind(string calldata _URI) external onlyOwner {
        URI = _URI;
    }

    function setAddressToBePayed(address _addressToBePayed) external onlyOwner {
        addressToBePayed = _addressToBePayed;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return URI;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "That token don't exists");
        return (addressToBePayed, (salePrice * 7) / 100);
    }
}