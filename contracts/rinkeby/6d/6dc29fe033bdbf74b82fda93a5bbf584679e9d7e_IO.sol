// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";

contract IO is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    address private signerAddress;

    address public constant MAIN_WALLET =
        0xfF3a0a8b9B38FCFe22E738b4639a6E978bf3B080;
    address public constant COMMUNITY_WALLET =
        0x84eB8d02819bD90C766d23370C8926D857ce1505;
    string public baseURI;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public constant COMMUNITY_SUPPLY = 100;
    uint256 public constant FOUNDERS_SUPPLY = 100;
    uint256 public constant PRE_SALE_SUPPLY = 4230;

    Counters.Counter public totalSupply;

    // Founders
    uint256 public foundersAmountMinted;
    mapping(address => bool) public foundersClaimed;

    // Community
    uint256 public communityAmountMinted;

    // Pre-Sale
    uint256 public floorPrice = 0.2 ether;
    mapping(address => uint256) public whitelistClaimed;
    bytes32 private merkleRoot;
    uint256 public preSaleAmountMinted;
    bool public isPreSaleLive;

    // Public Sale
    uint256 public publicSaleAmountMinted;
    mapping(address => uint256) public publicSaleClaimed;
    uint256 public constant PUBLIC_SALE_MINT_LIMIT = 1;

    // Public Sale DA price variables
    uint256 public publicSaleStartTime;
    uint256 public publicSaleStartPrice = 1.5 ether;
    uint256 public constant PUBLIC_SALE_DROP_INTERVAL = 900;
    uint256 public constant PUBLIC_SALE_DROP_AMOUNT = 0.1 ether;

    struct DADTO {
        uint256 price;
        uint256 currentTime;
    }

    error DirectMintFromContractNotAllowed();
    error PreSaleInactive();
    error ExceedsPreSaleSupply();
    error InsufficientETHSent();
    error ExceedsAllocatedForPreSale();
    error NotOnWhitelist();
    error PublicSaleInactive();
    error ExceedsMaxSupply();
    error ExceedsAllocatedForPublicSale();
    error DirectMintFromBotNotAllowed();
    error ExceedsAllocatedForFounders();
    error FounderClaimed();
    error ExceedsAllocatedForCommunity();
    error WithdrawalFailed();

    event Minted(uint256 remainingSupply);

    modifier callerIsUser() {
        if (tx.origin != msg.sender)
            revert DirectMintFromContractNotAllowed();
        _;
    }

    function getRemainingSupply() public view returns (uint256) {
        unchecked { return MAX_SUPPLY - totalSupply.current(); }
    }

    function isPublicSaleLive() public view returns (bool) {
        return
            publicSaleStartTime > 0 && block.timestamp >= publicSaleStartTime;
    }

    function getDAData() public view returns (DADTO memory data) {
        uint256 currentInterval = (block.timestamp - publicSaleStartTime) /
            PUBLIC_SALE_DROP_INTERVAL;

        uint256 dropPrice = currentInterval * PUBLIC_SALE_DROP_AMOUNT;

        DADTO memory price;

        price = publicSaleStartPrice > dropPrice &&
            publicSaleStartPrice - dropPrice > floorPrice
            ? DADTO(publicSaleStartPrice - dropPrice, block.timestamp)
            : DADTO(floorPrice, block.timestamp);

        return price;
    }

    function preSaleBuy(
        bytes32[] memory _merkleproof,
        uint256 allowedMintQuantity,
        uint256 mintQuantity
    ) external payable nonReentrant callerIsUser {
        if (!isPreSaleLive || isPublicSaleLive())
            revert PreSaleInactive();

        if (preSaleAmountMinted + mintQuantity > PRE_SALE_SUPPLY)
            revert ExceedsPreSaleSupply();

        if (whitelistClaimed[msg.sender] + mintQuantity > allowedMintQuantity)
            revert ExceedsAllocatedForPreSale();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, allowedMintQuantity));
        if (!MerkleProof.verify(_merkleproof, merkleRoot, leaf))
            revert NotOnWhitelist();

        if (msg.value < floorPrice * mintQuantity)
            revert InsufficientETHSent();

        unchecked {
            preSaleAmountMinted += mintQuantity;
            whitelistClaimed[msg.sender] += mintQuantity;
        }

        for (uint256 i; i < mintQuantity;) {
            totalSupply.increment();
            _mint(msg.sender, totalSupply.current());
            unchecked { ++i; }
        }

        emit Minted(getRemainingSupply());
    }

    function publicSaleBuy(bytes calldata signature)
        external
        payable
        nonReentrant
        callerIsUser
    {
        if (!isPublicSaleLive())
            revert PublicSaleInactive();

        if (totalSupply.current() + 1 > MAX_SUPPLY)
            revert ExceedsMaxSupply();

        if (publicSaleClaimed[msg.sender] + 1 > PUBLIC_SALE_MINT_LIMIT)
            revert ExceedsAllocatedForPublicSale();

        if (!matchAddresSigner(hashTransaction(msg.sender), signature))
            revert DirectMintFromBotNotAllowed();

        if (msg.value < getDAData().price)
            revert InsufficientETHSent();

        unchecked {
            publicSaleAmountMinted += 1;
            publicSaleClaimed[msg.sender] += 1;
        }

        totalSupply.increment();
        _mint(msg.sender, totalSupply.current());

        emit Minted(getRemainingSupply());
    }

    function matchAddresSigner(bytes32 hash, bytes memory signature)
        private
        view
        returns (bool)
    {
        return signerAddress == hash.recover(signature);
    }

    function hashTransaction(address sender) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(sender))
            )
        );
        return hash;
    }

    function foundersMint(address founderAddress)
        external
        onlyOwner
        nonReentrant
    {
        if (foundersAmountMinted + 20 > FOUNDERS_SUPPLY)
            revert ExceedsAllocatedForFounders();

        if (foundersClaimed[founderAddress])
            revert FounderClaimed();

        for (uint256 i; i < 20;) {
            totalSupply.increment();
            _mint(founderAddress, totalSupply.current());
            unchecked { ++i; }
        }

        unchecked { foundersAmountMinted += 20; }
        foundersClaimed[founderAddress] = true;

        emit Minted(getRemainingSupply());
    }

    function communityMint(uint256 mintQuantity)
        external
        onlyOwner
        nonReentrant
    {
        if (communityAmountMinted + mintQuantity > COMMUNITY_SUPPLY)
            revert ExceedsAllocatedForCommunity();

        for (uint256 i; i < mintQuantity;) {
            totalSupply.increment();
            _mint(COMMUNITY_WALLET, totalSupply.current());
            unchecked { ++i; }
        }

        unchecked { communityAmountMinted += mintQuantity; }

        emit Minted(getRemainingSupply());
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = payable(MAIN_WALLET).call{
            value: address(this).balance
        }("");

        if (!success)
            revert WithdrawalFailed();
    }

    function togglePreSaleStatus() external onlyOwner {
        isPreSaleLive = !isPreSaleLive;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPreSalePrice(uint256 _price) external onlyOwner {
        floorPrice = _price;
    }

    function setPublicSaleStartPrice(uint256 _price) external onlyOwner {
        publicSaleStartPrice = _price;
    }

    function setPublicSaleStartTime(uint256 _startTime) external onlyOwner {
        publicSaleStartTime = _startTime;
    }

    function setSignerAddress(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }
}