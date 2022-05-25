// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./EIP712.sol";

contract GoblinBoys is ERC721A, EIP712, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 5555;

    uint256 public price = 0.008 ether;

    uint256 public maxPerTx = 10;

    uint256 public maxFreeAmountForGoblintownHolders = 2000;

    uint256 public maxAmountForPerHolders = 2;

    uint256 public maxPerWallet = 60;

    uint256 public maxFreePerWallet = 2;

    uint256 public maxFreeAmount = 1500;

    bool public mintEnabled;

    bool public revealed;

    string public baseURI;

    string public unrevealedURI;

    uint256 mintedForHolders;

    mapping(address => uint256) private _mintedFreeAmount;

    bytes32 public constant MINT_CALL_HASH_TYPE =
        keccak256("mint(address receiver,uint256 amount)");

    address public cSigner;

    constructor() ERC721A("Goblin Boys", "GB") EIP712("Goblin Boys", "1") {
        _safeMint(msg.sender, 10);
    }

    function mint(uint256 amt) external payable {
        uint256 cost = price;
        bool freeMint = ((_mintedFreeAmount[msg.sender] + amt <=
            maxFreePerWallet) && (amt <= maxFreePerWallet)) ||
            msg.sender == owner();
        if (freeMint) {
            cost = 0;
        }

        require(msg.value >= amt * cost, "Please send the exact amount.");
        require(totalSupply() + amt < maxSupply + 1, "No more Goblin Boys");
        require(mintEnabled, "Minting is not live yet.");
        require(amt < maxPerTx + 1, "Max per TX reached.");
        require(
            _numberMinted(msg.sender) + amt <= maxPerWallet,
            "Too many per wallet!"
        );

        if (freeMint) {
            _mintedFreeAmount[msg.sender] += amt;
        }

        _safeMint(msg.sender, amt);
    }

    function goblinHolderMint(
        uint256 amountV,
        bytes32 r,
        bytes32 s
    ) external {
        uint256 amount = uint248(amountV);
        uint8 v = uint8(amountV >> 248);

        require(
            mintedForHolders + maxAmountForPerHolders <
                maxFreeAmountForGoblintownHolders,
            "No more free Goblin Boys for holders"
        );
        require(totalSupply() + 1 < maxSupply + 1, "No more Goblin Boys");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                ECDSA.toTypedDataHash(
                    _domainSeparatorV4(),
                    keccak256(
                        abi.encode(MINT_CALL_HASH_TYPE, msg.sender, amount)
                    )
                )
            )
        );
        require(ecrecover(digest, v, r, s) == cSigner, "Invalid signer");
        mintedForHolders += maxAmountForPerHolders;
        _safeMint(msg.sender, maxAmountForPerHolders);
    }

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
        return
            revealed
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : unrevealedURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setSigner(address signer) public onlyOwner {
        cSigner = signer;
    }

    function setUnrevealedURI(string memory uri) public onlyOwner {
        unrevealedURI = uri;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setMaxFreeAmount(uint256 _amount) external onlyOwner {
        maxFreeAmount = _amount;
    }

    function setMaxFreePerWallet(uint256 _amount) external onlyOwner {
        maxFreePerWallet = _amount;
    }

    function setMaxAmountForPerHolders(uint256 _amount) external onlyOwner {
        maxAmountForPerHolders = _amount;
    }

    function flipSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function flipReveal() external onlyOwner {
        revealed = !revealed;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}