pragma solidity 0.8.14;
// SPDX-License-Identifier: MIT
import "./ERC721A.sol";
import "./Ownable.sol";

contract GoblinVanGogh is ERC721A, Ownable {
    using Strings for uint256;
    string public baseURI;
    string public baseExtension = ".json";
    uint256 public publicCost = 0.0015 ether;
    bool public paused = false;
    uint256 public maxAmount = 15;
    uint256 public maxSupply = 10000;
    string public UnrevealedURI;
    bool public revealed = false;
    uint256 public freeQuantity = 1500;
    uint256 public freeMinted = 0;
    uint256 freeAmount = 3;
    uint256 public startTime = 1654542000;

    constructor() ERC721A("GoblinVanGogh", "GoblinVanGogh") {
        setBaseURI("ipfs://QmRCGZsRte7NXUqNaKkHSsb5iNEEuLDihJpWx6D62iWpAT/");
        setUnrevealedUri(
            "ipfs://QmWTKRUAqJuqNKGtC3VtjFnVEy4MKHKNDE5SyRaLasZPAf/"
        );
    }

    function mint(uint256 quantity) external payable {
        uint256 supply = totalSupply();
        require(!paused, "The contract is paused!");
        require(quantity > 0, "Quantity Must Be Higher Than Zero");
        require(supply + quantity <= maxSupply, "Max Supply Reached");

        if (msg.sender != owner()) {
            require(block.timestamp >= startTime, "Mint didn't start yet");
            uint256 balance = balanceOf(msg.sender);
            uint256 paidNFTs = 0;
            uint256 freeNFTs = 0;

            if (balance <= freeAmount && freeMinted <= freeQuantity) {
                uint256 total = balance + quantity;
                if (total >= freeAmount) {
                    freeNFTs = freeAmount - balance;
                    paidNFTs = total - freeAmount;
                    freeMinted += freeNFTs;
                    require(
                        msg.value >= publicCost * paidNFTs,
                        "Insufficient Funds"
                    );
                } else {
                    freeMinted += quantity;
                }
            } else if (freeMinted >= freeQuantity) {
                require(
                    msg.value >= publicCost * quantity,
                    "Insufficient Funds"
                );
            } else if (balance >= freeAmount) {
                require(
                    msg.value >= publicCost * quantity,
                    "Insufficient Funds"
                );
            } else if (balance < freeAmount) {
                freeMinted += quantity;
            }

            require(
                balanceOf(msg.sender) + quantity <= maxAmount,
                "youre not allowed to hold that much"
            );
        }
        _safeMint(msg.sender, quantity);
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

        if (revealed == false) {
            return UnrevealedURI;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function Set(uint256 _publicCost, uint256 _maxAmount) public onlyOwner {
        publicCost = _publicCost;
        maxAmount = _maxAmount;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setStartTime(uint256 _startTime) public onlyOwner {
        startTime = _startTime;
    }

    function setFreeQuantity(uint256 _freeQuantity, uint256 _freeAmount)
        public
        onlyOwner
    {
        freeQuantity = _freeQuantity;
        freeAmount = _freeAmount;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setUnrevealedUri(string memory _UnrevealedUri) public onlyOwner {
        UnrevealedURI = _UnrevealedUri;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function withdraw() public onlyOwner {
        (bool y, ) = payable(0x6e0d7933d3dFB019777beFda09eB065D5d79a49e).call{
            value: address(this).balance / 5
        }(""); // developer wallet
        require(y);
        (bool ts, ) = payable(owner()).call{value: address(this).balance}("");
        require(ts);
    }
}