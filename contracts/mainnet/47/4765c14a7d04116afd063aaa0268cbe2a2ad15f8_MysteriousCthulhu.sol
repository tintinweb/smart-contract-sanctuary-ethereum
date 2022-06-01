pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

// import "hardhat/console.sol";
import "./ERC721A.sol";
import "./Ownable.sol";

contract MysteriousCthulhu is ERC721A, Ownable {

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    bool public publicSaleOpen;
    bool public freeSaleOpen;
    string public _baseTokenURI;
    uint256 public constant MAX_FREE_PER_TX = 1;
    uint256 public constant MAX_FREE_SUPPLY = 545;
    
    uint256 public constant MAX_PER_TX = 3;
    // uint256 public constant MAX_PER_WALLET = 10;
    uint256 public constant MAX_SUPPLY = 1245;
    uint256 public constant COST_PER_MINT = 0.003 ether;

    mapping(address => bool) public userMintedFree;

    constructor() ERC721A("MysteriousCthulhu", "MC") {
        publicSaleOpen = false;
        freeSaleOpen = false;
    }

    function togglePublicSale() public onlyOwner {
        publicSaleOpen = !(publicSaleOpen);
    }

    function toggleFreeSale() public onlyOwner {
        freeSaleOpen = !(freeSaleOpen);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function publicMint(uint256 numOfTokens) external payable callerIsUser {
        require(publicSaleOpen, "Sale is not active yet");
        require(totalSupply() + numOfTokens < MAX_SUPPLY, "Exceed max supply"); 
        require(numOfTokens <= MAX_PER_TX, "Can't claim more than 3 in a tx");
        // require(numberMinted(msg.sender) + numOfTokens <= MAX_PER_WALLET, "Cannot mint this many");
        require(msg.value >= COST_PER_MINT * numOfTokens, "Insufficient ether provided to mint");

        _safeMint(msg.sender, numOfTokens);
    }

    function freeMint(uint256 numOfTokens) external callerIsUser {
        require(freeSaleOpen, "Free Sale is not active yet");
        require(!userMintedFree[msg.sender], "User max free limit");
        require(totalSupply() + numOfTokens < MAX_FREE_SUPPLY, "Exceed max free supply, use publicMint to mint"); 
        require(numOfTokens <= MAX_FREE_PER_TX, "Can't claim more than 1 for free");

        userMintedFree[msg.sender] = true;
        _safeMint(msg.sender, numOfTokens);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    // get the funds from the minting of the NFTs
    function retrieveFunds() public onlyOwner {
        uint256 balance = accountBalance();
        require(balance > 0, "No funds to retrieve");
        
        _withdraw(payable(msg.sender), balance);
    }

    function _withdraw(address payable account, uint256 amount) internal {
        (bool sent, ) = account.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function accountBalance() internal view returns(uint256) {
        return address(this).balance;
    }

    function ownerMint(address mintTo, uint256 numOfTokens) external onlyOwner {
        _safeMint(mintTo, numOfTokens);
    }

    function isSaleOpen() public view returns (bool) {
        return publicSaleOpen;
    }

    function isFreeSaleOpen() public view returns (bool) {
        return freeSaleOpen && totalSupply() < MAX_FREE_SUPPLY;
    }

}