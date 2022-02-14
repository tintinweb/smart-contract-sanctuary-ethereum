// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./Helper.sol";

contract CryptoHippos is ERC721A, Ownable, PullPayment {
    using Strings for uint256;
    using MerkleProof for bytes32;

    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;
    uint256 public cost = 0.02 ether;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 5;
    uint256 public nftPerAddressLimit = 5;
    uint256 public nftReserved = 175;
    bool public paused = false;
    bool public onlyWhitelisted = true;
    mapping(address => uint256) public addressMintedBalance;
    bytes32 public rootHash =
        0xd227ba3c0d84000375a7b712e9dedf829760728f7ac90f8056723cd6bb757257;
    address private Address1 = 0xC85bA6c679dA5d0f89E793Aa10938F6dE98e6Ef2;
    address private Address2 = 0xBbB589796d01EF05f24C49f57d53125d4382ab62;
    address private Address3 = 0x2Be08be360bd2ef8A7231F44997432D15F80c9b1;
    address private Address4 = 0x2Be08be360bd2ef8A7231F44997432D15F80c9b1;
    address private Address5 = 0x4d418A6A3e9BEb980986a32D49250d084a7E089A;
    constructor() ERC721A("CryptoHippos", "CH", maxMintAmount, maxSupply) {
        setBaseURI("https://cryptohipponft.com/");
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        require(!paused, "CryptoHippos Sale is not currently live");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(
            _mintAmount <= maxMintAmount,
            "You can only mint 5 per transaction"
        );
        require(supply + _mintAmount <= maxSupply, "All CryptoHippos have been minted");

        require(!onlyWhitelisted, "Use whitelist mint function if you are on the whitelist");

        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        // require(
        //     ownerMintedCount + _mintAmount <= nftPerAddressLimit,
        //     "max NFT per address exceeded"
        // );
        require(msg.value >= cost * _mintAmount, "insufficient funds");
        _safeMint(msg.sender, _mintAmount);
    }

    function whiteListedMint(
        bytes32[] calldata _merkleProof,
        uint256 _mintAmount
    ) public payable {
        require(!paused);
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply, "All CryptoHippos have been minted");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, rootHash, leaf),
            "You are not whitelisted."
        );

        require(onlyWhitelisted);
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(
            ownerMintedCount + _mintAmount <= nftPerAddressLimit,
            "You can only mint up to 5 CryptoHippos during whitelist sale, wait for public sale to do more than 5."
        );
        require(msg.value >= cost * _mintAmount);
        _safeMint(msg.sender, _mintAmount);
        addressMintedBalance[msg.sender] = addressMintedBalance[msg.sender] + _mintAmount;

    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
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
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    //only owner

    function mintForAddress(uint256 _mintAmount, address _receiver)
        external
        onlyOwner
    {
        require(_mintAmount > 0, "Must be greater than 0");
        require(_mintAmount <= nftReserved);
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply, "All CryptoHippos have been minted");
        _safeMint(_receiver, _mintAmount);
    }

    function setRootHash(bytes32 _rootHash) public onlyOwner {
        rootHash = _rootHash;
    }

    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function reserveToCustomWallet(address _walletAddress, uint256 _count) external payable onlyOwner {
        require(_count > 0, "need to mint at least 1 NFT");
        require(_count < 6, "need to mint max of 5 NFTs");
        uint256 supply = totalSupply();
        require(supply + _count <= maxSupply, "max NFT limit exceeded");
        for (uint256 i = 1; i <= _count; i++) {
            //addressMintedBalance[msg.sender]++;
            // didnt update address mapping because this is intended for marketing 
            // and we could want to mint more than 5/they may mint themselves during sale
            _safeMint(msg.sender, supply + i);
        }
    }

    function withdraw() public payable onlyOwner {
        //TODO: update the split logic
        uint256 balance = address(this).balance; // ex. - 100 eth
        uint256 balance1 = balance - (balance * 5050 / 10000); // 49.5 eth
        balance = balance - (balance * 4950 / 10000); // 50.5 eth
        uint256 balance2 = balance - (balance * 2476 / 10000); // 38 eth
        balance = balance - (balance * 7524 / 10000); // 12.5 eth
        uint256 balance3 = balance - (balance * 6000 / 10000); // 5 eth
        balance = balance - (balance * 4000 / 10000); // 7 eth
        uint256 balance4 = balance3 - (balance3 * 4000 / 10000);// 4.5 eth
        balance = balance - (balance * 6000 / 10000); // 3.5 eth
        uint256 balance5 = balance; // 3.5 eth
        _asyncTransfer(Address1, balance1);
        _asyncTransfer(Address2, balance2);
        _asyncTransfer(Address3, balance3);
        _asyncTransfer(Address4, balance4);
        _asyncTransfer(Address5, balance5);
    }
}