// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

//@author Soakverse
//@title Eggz by Soakverse

import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ERC721LockRegistry.sol";

contract RollzNFT is Ownable, ERC721X {
    using Strings for uint256;

    enum Step {
        Before,
        OGWhitelist,
        PremiumWhitelist,
        Whitelist,
        Public,
        Soldout
    }

    string public baseURI;

    Step public sellingStep;

    uint256 private constant MAX_SUPPLY = 5000;
    uint256 private constant MAX_FREEMINT = 4580;

    bytes32 public ogMerkleRoot;
    bytes32 public premiumMerkleRoot;
    bytes32 public merkleRoot;

    mapping(address => uint256) public amountNftPerWallet;

    bool public canStake;

    mapping(uint256 => uint256) public tokensLastStakedAt; // tokenId => timestamp

    event Stake(uint256 tokenId, address by, uint256 stakedAt);
    event Unstake(
        uint256 tokenId,
        address by,
        uint256 stakedAt,
        uint256 unstakedAt
    );

    constructor(
        bytes32 _ogMerkleRoot,
        bytes32 _premiumMerkleRoot,
        bytes32 _merkleRoot,
        string memory _baseURI
    ) ERC721X("Rollz", "ROLLZ") {
        ogMerkleRoot = _ogMerkleRoot;
        premiumMerkleRoot = _premiumMerkleRoot;
        merkleRoot = _merkleRoot;
        baseURI = _baseURI;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function ogWhitelistMint(uint256 _quantity, bytes32[] calldata _proof)
        external
        callerIsUser
    {
        require(
            sellingStep >= Step.OGWhitelist,
            "Whitelist sale is not activated"
        );
        require(
            isOGWhiteListed(msg.sender, _quantity, _proof),
            "Not OG whitelisted"
        );
        require(
            amountNftPerWallet[msg.sender] + _quantity <= _quantity,
            "You reached maximum on OG Whitelist Sale"
        );
        require(
            totalSupply() + _quantity <= MAX_FREEMINT,
            "Max freemint supply exceeded"
        );
        amountNftPerWallet[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function premiumWhitelistMint(bytes32[] calldata _proof)
        external
        callerIsUser
    {
        require(
            sellingStep >= Step.PremiumWhitelist,
            "Premium Whitelist sale is not activated"
        );
        require(
            isPremiumWhiteListed(msg.sender, _proof),
            "Not Premium whitelisted"
        );
        require(
            amountNftPerWallet[msg.sender] + 2 <= 2,
            "You can only get 2 NFT on the Premium Whitelist Sale"
        );
        require(
            totalSupply() + 2 <= MAX_FREEMINT,
            "Max freemint supply exceeded"
        );
        amountNftPerWallet[msg.sender] += 2;
        _safeMint(msg.sender, 2);
    }

    function whitelistMint(bytes32[] calldata _proof) external callerIsUser {
        require(
            sellingStep >= Step.Whitelist,
            "Whitelist sale is not activated"
        );
        require(isWhiteListed(msg.sender, _proof), "Not whitelisted");
        require(
            amountNftPerWallet[msg.sender] + 1 <= 1,
            "You can only get 1 NFT on the Whitelist Sale"
        );
        require(
            totalSupply() + 1 <= MAX_FREEMINT,
            "Max freemint supply exceeded"
        );
        amountNftPerWallet[msg.sender] += 1;
        _safeMint(msg.sender, 1);
    }

    function mint() external callerIsUser {
        require(sellingStep >= Step.Public, "Public sale is not activated");
        require(
            amountNftPerWallet[msg.sender] + 1 <= 1,
            "You can only get 1 NFT on the Public Sale"
        );
        require(
            totalSupply() + 1 <= MAX_FREEMINT,
            "Max freemint supply exceeded"
        );
        amountNftPerWallet[msg.sender] += 1;
        _safeMint(msg.sender, 1);
    }

    function giveaway(address _to, uint256 _quantity) external onlyOwner {
        require(sellingStep > Step.Public, "Giveaway is after the public sale");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        _safeMint(_to, _quantity);
    }

    function setStep(uint256 _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    // ---- OG Whitelist ----
    function setOGMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        ogMerkleRoot = _merkleRoot;
    }

    function isOGWhiteListed(
        address _account,
        uint256 _quantity,
        bytes32[] calldata _proof
    ) internal view returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(_account, _quantity));
        return _verify(_leaf, ogMerkleRoot, _proof);
    }

    // ---- Premium Whitelist ----
    function setPremiumMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        premiumMerkleRoot = _merkleRoot;
    }

    function isPremiumWhiteListed(address _account, bytes32[] calldata _proof)
        internal
        view
        returns (bool)
    {
        bytes32 _leaf = keccak256(abi.encodePacked(_account));
        return _verify(_leaf, premiumMerkleRoot, _proof);
    }

    // ---- Whitelist ----
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function isWhiteListed(address _account, bytes32[] calldata _proof)
        internal
        view
        returns (bool)
    {
        bytes32 _leaf = keccak256(abi.encodePacked(_account));
        return _verify(_leaf, merkleRoot, _proof);
    }

    function _verify(
        bytes32 _leaf,
        bytes32 _root,
        bytes32[] memory _proof
    ) internal pure returns (bool) {
        return MerkleProof.verify(_proof, _root, _leaf);
    }

    // ---- STAKING ----
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721X) {
        require(
            tokensLastStakedAt[tokenId] == 0,
            "Cannot transfer staked token"
        );
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable override(ERC721X) {
        require(
            tokensLastStakedAt[tokenId] == 0,
            "Cannot transfer staked token"
        );
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function stake(uint256 tokenId) public {
        require(canStake, "staking not open");
        require(
            msg.sender == ownerOf(tokenId) || msg.sender == owner(),
            "caller must be owner of token or contract owner"
        );
        require(tokensLastStakedAt[tokenId] == 0, "already staking");
        tokensLastStakedAt[tokenId] = block.timestamp;
        emit Stake(tokenId, msg.sender, tokensLastStakedAt[tokenId]);
    }

    function unstake(uint256 tokenId) public {
        require(
            msg.sender == ownerOf(tokenId) || msg.sender == owner(),
            "caller must be owner of token or contract owner"
        );
        require(tokensLastStakedAt[tokenId] > 0, "not staking");
        uint256 lsa = tokensLastStakedAt[tokenId];
        tokensLastStakedAt[tokenId] = 0;
        emit Unstake(tokenId, msg.sender, block.timestamp, lsa);
    }

    function setTokensStakeStatus(uint256[] memory tokenIds, bool setStake)
        external
    {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (setStake) {
                stake(tokenId);
            } else {
                unstake(tokenId);
            }
        }
    }

    function setCanStake(bool b) external onlyOwner {
        canStake = b;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "there is nothing to withdraw");
        _withdraw(owner(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "could not withdraw");
    }
}