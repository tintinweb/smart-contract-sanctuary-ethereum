// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract NFT_DH is ERC721A, ERC721ABurnable, Ownable {
    uint256 public price;
    uint256 public maxQuantity;
    uint256 maxPerWallet;
    uint256 allowListRequired;
    string contractURL;
    string baseURI;
    address proxyRegistryAddress;
    bytes32 public merkleRoot;
    mapping(address => uint256) private _minted;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initPrice,
        uint256 initQuantity,
        string memory uri,
        address proxy
    ) ERC721A(name, symbol) {
        price = initPrice;
        maxQuantity = initQuantity;
        maxPerWallet = 0;
        allowListRequired = 1;
        baseURI = uri;
        proxyRegistryAddress = proxy;
    }

    function isOnAllowlist(bytes32[] memory _proof, address _claimer)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_claimer));
        return MerkleProof.verify(_proof, merkleRoot, leaf);
    }

    // set merkle root
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // set merkle root and maxperWallet
    function setMerkleRootAndMaxPerWallet(
        bytes32 _merkleRoot,
        uint256 _maxPerWallet
    ) public onlyOwner {
        merkleRoot = _merkleRoot;
        maxPerWallet = _maxPerWallet;
    }

    function setMaxPerWallet(uint256 max) public onlyOwner {
        maxPerWallet = max;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    // Set allowlisting on/off (1/0)
    function setAllowListRequired(uint256 value) public onlyOwner {
        allowListRequired = value;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function contractURI() public view returns (string memory) {
        return contractURL;
    }

    function mintedBalanceOf(address _address) public view returns (uint256) {
        return _minted[_address];
    }

    function setContractURI(string memory _contractURL) public onlyOwner {
        contractURL = _contractURL;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
     * Update it with setProxyAddress
     */
    function setProxyAddress(address _a) public onlyOwner {
        proxyRegistryAddress = _a;
    }

    function airdrop(address[] memory addresses) public onlyOwner {
        uint256 length = addresses.length;
        require(
            _totalMinted() + length <= maxQuantity,
            "Cannot mint that many tokens."
        );
        for (uint256 i = 0; i < length; i++) {
            _mint(addresses[i], 1);
        }
    }

    function mintPublic(uint256 quantity) external payable {
        require(allowListRequired == 0, "Must use the allow list.");
        require(
            _totalMinted() + quantity <= maxQuantity,
            "Cannot mint that many tokens."
        );
        require(
            _minted[_msgSender()] + quantity <= maxPerWallet,
            "Cannot mint that many tokens."
        );
        require(msg.value >= quantity * price, "Not enough to pay for that");
        _mint(msg.sender, quantity);
        _minted[_msgSender()] = _minted[_msgSender()] + quantity;
    }

    function mintAllowed(uint256 quantity, bytes32[] memory _proof)
        external
        payable
    {
        require(allowListRequired == 1, "Allow list is disabled.");
        require(
            isOnAllowlist(_proof, _msgSender()),
            "You are not on the allow list."
        );
        require(
            _totalMinted() + quantity <= maxQuantity,
            "Cannot mint that many tokens."
        );
        require(
            _minted[_msgSender()] + quantity <= maxPerWallet,
            "Cannot mint that many tokens."
        );
        require(msg.value >= quantity * price, "Not enough to pay for that");
        _mint(msg.sender, quantity);
        _minted[_msgSender()] = _minted[_msgSender()] + quantity;
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }

    // overrides

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}