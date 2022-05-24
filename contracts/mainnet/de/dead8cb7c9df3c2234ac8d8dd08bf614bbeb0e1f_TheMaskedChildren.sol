pragma solidity ^0.8.14;

import "./ERC721A.sol";
import "./Ownable.sol";

contract TheMaskedChildren is ERC721A, Ownable{

    uint256 public constant MAX_CHILDREN = 1000;
    uint256 public constant PRICE = .00 ether;
    uint256 public constant MAX_PER_TX = 5;
    uint256 public constant MAX_PER_WALLET = 10;

    bool public saleIsActive = false;

    string public baseTokenURI;


    constructor() ERC721A ("TheMaskedChildren", "TMC") {}

    function toggleSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function mint(uint amountToMint) public payable{
        uint256 total = _totalMinted();
        require(msg.sender == tx.origin, "Contract's are not allowed to mint.");
        require(saleIsActive, "Sale is not active.");
        require(amountToMint > 0, "You have to mint at least 1 child.");
        require(amountToMint <= MAX_PER_TX, "Can only mint 5 tokens at a time.");
        require(_numberMinted(msg.sender) + amountToMint <= MAX_PER_WALLET, "This wallet has minted the max tokens allowed.");
        require(amountToMint + total <= MAX_CHILDREN, "The number exceeds the amount of available children to mint.");
        require(total < MAX_CHILDREN, "The sale is complete.");

        _safeMint(msg.sender, amountToMint);
        
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ETH is available to withdraw.");
        payable(msg.sender).transfer(balance);
    }
    

}