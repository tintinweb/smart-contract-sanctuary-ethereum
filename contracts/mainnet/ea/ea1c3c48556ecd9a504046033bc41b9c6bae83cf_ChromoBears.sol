pragma solidity 0.8.13;
// SPDX-License-Identifier: MIT
import "./ERC721A.sol";
import "./Ownable.sol";

contract ChromoBears is ERC721A, Ownable {
    using Strings for uint256;
    string public baseURI;
    mapping(uint256 => bool) public isOwnerMint; // if the NFT was freely minted by owner
    mapping(uint256 => bool) public hasRefunded; // users can search if the NFT has been refunded
    bool public paused = true;
    uint256 public maxPublic = 10;
    uint256 public maxSupply = 1496;
    uint256 public constant refundPeriod = 14 days;
    uint256 public refundEndTime;
    address public refundAddress;
    

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
        refundAddress = msg.sender;
        toggleRefundCountdown();
    }

    function mint(uint256 quantity) external payable {
        uint256 price = getCurrentPrice();
        uint256 supply = totalSupply();
        require(!paused, "The contract is paused!");
        require(quantity > 0, "Quantity Must Be Higher Than Zero");
        require(supply + quantity <= maxSupply, "Max Supply Reached");
            require(
                quantity <= maxPublic,
                "You're Not Allowed To Mint more than maxMint Amount"
            );
        
            require(msg.value >= price * quantity, "Insufficient Funds Please Top Up");

        
        _safeMint(msg.sender, quantity);
    }


    function ownerMint(uint256 quantity) external onlyOwner {
        uint256 supply = totalSupply();
        require(quantity > 0, "Quantity Must Be Higher Than Zero");
        require(supply + quantity <= maxSupply, "Max Supply Reached");
        _safeMint(msg.sender, quantity);

        for (uint256 i = currentIndex - quantity; i < currentIndex; i++) {
            isOwnerMint[i] = true;
        }
    }

    function isRefundGuaranteeActive() public view returns (bool) {
        return (block.timestamp <= refundEndTime);
    }

    function getRefundGuaranteeEndTime() public view returns (uint256) {
        return refundEndTime;
    }

    function refund(uint256[] calldata tokenIds) external {
        require(isRefundGuaranteeActive(), "Refund expired");
        uint256 totalCost = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(msg.sender == ownerOf(tokenId), "Not token owner");
            require(!hasRefunded[tokenId], "Already refunded");
            require(!isOwnerMint[tokenId], "Freely minted NFTs cannot be refunded");
            hasRefunded[tokenId] = true;
            transferFrom(msg.sender, refundAddress, tokenId);
            totalCost += _ETHAmount[tokenId];
        }

        Address.sendValue(payable(msg.sender), totalCost);
        totalCost = 0; 
    }

    

    function toggleRefundCountdown() public onlyOwner {
        refundEndTime = block.timestamp + refundPeriod;
    }

    function setRefundAddress(address _refundAddress) external onlyOwner {
        refundAddress = _refundAddress;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString()
                    )
                )
                : "";
    }

    function Set(uint256 _publicCost, uint256 _publicMax) public onlyOwner {
        publicCost = _publicCost;
        maxPublic = _publicMax;
    }

    function setPresale(bool _presaleEnabled) public onlyOwner {
        presaleEnabled = _presaleEnabled;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() public onlyOwner {
        require(block.timestamp > refundEndTime, "Refund period not over");
        (bool ts, ) = payable(owner()).call{value: address(this).balance}("");
        require(ts);
    }
}