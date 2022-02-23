// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./IERC20.sol";

/** @dev Contract definition */
contract MetaHearts is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    /** @dev Contract constructor. Defines mapping between index and atributes.*/
    constructor() ERC721("MetaHearts", "MH") {
        // TODO : To fill
        isWhitelisted[0x3058047bEDe41BA5e9B6f20B9eB30e538546dC56] = true;
        isWhitelisted[0x0A2cEb457115fEbf127D6A1902361A2E30949aFd] = true;
        isWhitelisted[0x10f555351f49306828dF23194B9Bbf70f0323331] = true;
        isWhitelisted[0xa9166B04162F77813a02453e392766d0F860c8cF] = true;
        isWhitelisted[0x712ca5956D68A03F4F098791EDdD37E846422b32] = true;
        isWhitelisted[0xc0F6135e81A3bBB3e622d3899780374018EB2052] = true;
        isWhitelisted[0xD96B66ce05462f2EC8625311414D7da396d496a6] = true;
        isWhitelisted[0x470edAb50d941b2f88DaBB182b7C3cfF5d545810] = true;
        isWhitelisted[0x026a36cD623ADAcDc1676DcB3dC4A9D1f32208E2] = true;
        isWhitelisted[0xAf692770eb4600296B1e54a5C3da31e87759E989] = true;
        isWhitelisted[0x6888a5B9B0Fe41f0563895faE710d7EB1F36e64f] = true;
        isWhitelisted[0x930CC2D3B9EfACd0dE50d5353b2b466cebF33B35] = true;
        isWhitelisted[0xF2bf6e03A38199EFbFd8Ef2F169d601db90b244A] = true;
        isWhitelisted[0xe9ab2d53B08647A971B517c8d1B162B0a1E10669] = true;
        isWhitelisted[0xfD9336aC69bF2844F712D2e7825ccF202C985881] = true;
        isWhitelisted[0x08E50b0aeAC4A4e54876E487A63CCf3f7b8a455F] = true;
        isWhitelisted[0xaEA6ba18620b9F93CEAb77DC5Fb56250444bCb98] = true;
        isWhitelisted[0x755f1A2130A5Fb4874A3dE207C6876f8dE1532Ee] = true;
        isWhitelisted[0x82f7d87115299F2950177dD2d881753e39E6eBb8] = true;
        isWhitelisted[0xA10D517D591268017c24a4caAB300e9471A8FcaB] = true;
        isWhitelisted[0x379de6aB1E1c06F39F979888FD7dedf9dD1b717e] = true;
        isWhitelisted[0x541b79b200B40D37F91663e40Ca0B05512d0EB05] = true;
        isWhitelisted[0x869E98C25496fc27D235E9Fb547D634171F553E9] = true;
        isWhitelisted[0xfdD0b3f5aA26Cf75f0618689D0f27698Ea1F97F1] = true;
        isWhitelisted[0x9EC03728708423E6F75Eb1502447F7C554d88106] = true;
        isWhitelisted[0x1A67C63582EcD79C4e76177B356C8BEb83fb5685] = true;
        isWhitelisted[0xf997A2687cd52D6Db8885c280C70Fcf7986185f8] = true;
        isWhitelisted[0xD9a28293d20885135251e0eE54111728c28210e7] = true;
        isWhitelisted[0xC3df326A2d3aa5f45147bc61EDFd00cBd4Ab2Fd3] = true;
        isWhitelisted[0xa9166B04162F77813a02453e392766d0F860c8cF] = true;
        isWhitelisted[0x4D80A9C3D75Aa199e41d1781BCE4483be4F2AE31] = true;
        isWhitelisted[0xECb934E87Fb5797b6cD0B9B7dE3B4f9ceafdDe1a] = true;
        isWhitelisted[0x923fbc6B5ba1014cA771E857f8FAA941a51805D7] = true;
        isWhitelisted[0xeB8B45591C6F27299224D1620A85C3D696b7B944] = true;
        isWhitelisted[0x77C56524748bF3F31d7F77C650B10C0964eD99fB] = true;
        isWhitelisted[0x2Ec0161bB50e3c1eB30C1f1Cbf7d95F3083D54b2] = true;
        isWhitelisted[0xE4A46E1e5173a92BBf69c55a1A9B0517ae1a7115] = true;
        isWhitelisted[0x1C732Fb3DCD22d592738106c41f7A3A3Bd45d24C] = true;
        isWhitelisted[0xd5145D7b5186811F134E47830139236f7153Da5B] = true;
        isWhitelisted[0x0E373D1B219c8473B72287B23B36d8b6e43AD72a] = true;
        isWhitelisted[0xE47E168364aD555f74221f61682dA762c7F889dD] = true;
        isWhitelisted[0x098132A7fd334C1877a9563FFD2547eE8bFdBf26] = true;
        isWhitelisted[0x8eb9202CB8608D251e4Ac6683513FF1501AC749B] = true;
        isWhitelisted[0x7Ccd2c8f803Ddf8392aB66FfF7F4B42f9FeD035a] = true;
        isWhitelisted[0x9C19D1e78A4b5b00BC6eE1eD5225352A4a791469] = true;
        isWhitelisted[0xC2adcd1d98fAa880550381A509C741B98406039d] = true;
        isWhitelisted[0xD068f872CFC6B59321a86f5b4727d478FFb02a65] = true;
        isWhitelisted[0x078Be78d01aF868Fcf77eD611aF01b4a3710d428] = true;
        isWhitelisted[0x470edAb50d941b2f88DaBB182b7C3cfF5d545810] = true;
        isWhitelisted[0x6afD748A870B14Ba9000088090f8cb3Ce407D8e3] = true;
        isWhitelisted[0x7C9c6a04342c11C827e87Ce116f06D22d50Aad1b] = true;
        isWhitelisted[0x88200537364161e43e585CC31eeb056F711cef9B] = true;
        isWhitelisted[0x9E5A44F6984D9b90a04dEAB5D24630b9B502cC56] = true;
        isWhitelisted[0xA7BF319D12eefC614CeBaEcde98d41d0335D38E2] = true;
        isWhitelisted[0xdb8A644a6A82bfC818b2014dD8312b1C9aB7Bf19] = true;
        isWhitelisted[0xd2D6a441C2C3E45D1C5213bac7c7da958e931C0E] = true;
        isWhitelisted[0xe8b78E0562D18ab7FeB427E6AC24ed49B4b61EEE] = true;
        isWhitelisted[0x21Ce3ac9162Def133a09582138804eD3A30bE16d] = true;
        isWhitelisted[0xf1bF0130b895F6ef500410CE8C29A9D662290Ebe] = true;
        isWhitelisted[0x2a723aDa4Bd50f9e6B3626ccafF6559c6770c2B5] = true;
        isWhitelisted[0xfdD0b3f5aA26Cf75f0618689D0f27698Ea1F97F1] = true;
        isWhitelisted[0x026a36cD623ADAcDc1676DcB3dC4A9D1f32208E2] = true;
        isWhitelisted[0x70896F42433c446F5D1a36adeB974A029203DE08] = true;
        isWhitelisted[0x03677337AdF578F781cECA288c2A0A0C7CeB5569] = true;
        isWhitelisted[0x0A2cEb457115fEbf127D6A1902361A2E30949aFd] = true;
        // TODO : To fill
        canMintForFree[0x3058047bEDe41BA5e9B6f20B9eB30e538546dC56] = true;
        canMintForFree[0x0A2cEb457115fEbf127D6A1902361A2E30949aFd] = true;
        canMintForFree[0xaF4A5dabb5d922B4CDAA5fDf2EdDABade6895f85] = true;
        canMintForFree[0x38E14301eB0cfc215b71Af4AE9DaF30ba16052bE] = true;
        canMintForFree[0xB53f5B02090e6474E6B36554aD2EcB279e5A6A2E] = true;
        canMintForFree[0x9976f235803bA233cCb5C3F54A47c5600f2a2353] = true;
        canMintForFree[0xb53c3ba1325128B347CEc5C8B4a57Db9A3f0e8D8] = true;
        canMintForFree[0x82d92424FE1a6E3fa3C706429BeAeB9Db9C5C5b0] = true;
        canMintForFree[0x24adF732C47DE85ca1E4584988307d92e7C0457c] = true;
        canMintForFree[0xD3214bcBf2178753f767E4A4aa29a9C2f37C0d94] = true;
        canMintForFree[0x0A2cEb457115fEbf127D6A1902361A2E30949aFd] = true;
        canMintForFree[0x04767EB4363cDb2fDF9C4c872459b8a4bb50689c] = true;
    }

    /** @dev Will be set to true when reveal is done.*/
    bool isRevealed = false;

    /** @dev Will be set to true when reveal is done.*/
    string beforeRevealMetadata = "";

    /** @dev Defines if an address is whitelisted.*/
    mapping(address => bool) isWhitelisted;

    /** @dev defines address that can mint for free.*/
    mapping(address => bool) canMintForFree;

    /** @dev Devs' addresses. Where token will be sent when withdraw is called.*/
    address payable[2] withdrawAddresses = [
        payable(0x3058047bEDe41BA5e9B6f20B9eB30e538546dC56),
        payable(0x0A2cEb457115fEbf127D6A1902361A2E30949aFd)
    ];

    /** @dev Devs' per thousand tokens sent when withdraw is called.*/
    uint16[2] private perThousandPerAddress = [900, 100];

    /** @dev Price for miniting one NFT, in wei.*/
    uint256 public publicPrice = 7e16;

    /** @dev Maximum miniting possible for public.*/
    uint256 public publicMaxMint = 10;
    uint256 public publicMaxOwned = 100;

    /** @dev Price for miniting one NFT, in wei.*/
    uint256 public whitelistPrice = 5e16;

    /** @dev Maximum miniting possible for whitelisted.*/
    uint256 public whitelistMaxMint = 5;
    uint256 public whitelistMaxOwned = 50;

    /** @dev Extension of base URI. Used to move metadata files if needed.*/
    string private _baseURIextended;

    /** @dev Max number of NFTs to mint.*/
    uint16 public NFTsLimit = 2500;

    /** @dev NFTs minted.*/
    uint16 public NFTsMinted = 0;

    /** @dev _beforeTokenTransfer must be overriden to make compiler happy.*/
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /** @dev Changing baseUri to move metadata files and images if needed.*/
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    /** @dev Changing miniting price if needed.*/
    function setPublicPrice(uint256 newPrice) external onlyOwner {
        publicPrice = newPrice;
    }

    /** @dev Changing miniting price if needed.*/
    function setBeforeRevealMetadata(string memory metadata)
        external
        onlyOwner
    {
        beforeRevealMetadata = metadata;
    }

    /** @dev Changing miniting price if needed.*/
    function setWhitelistPrice(uint256 newPrice) external onlyOwner {
        whitelistPrice = newPrice;
    }

    /** @dev Override of _baseUri().*/
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (isRevealed) {
            return super.tokenURI(tokenId);
        }
        return beforeRevealMetadata;
    }

    /** @dev Override of supportsInterface().*/
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /** @dev withdrawing tokens received from miniting price.*/
    function withdraw() public {
        uint256 balance = address(this).balance;
        uint256 remainingBalance = balance;
        for (uint8 i = 0; i < withdrawAddresses.length - 1; i++) {
            uint256 valueToTransfer = (perThousandPerAddress[i] * balance) /
                1000;
            withdrawAddresses[i].transfer(valueToTransfer);
            remainingBalance -= valueToTransfer;
        }
        withdrawAddresses[withdrawAddresses.length - 1].transfer(
            remainingBalance
        );
    }

    /** @dev withdrawing tokens of an IERC contract.*/
    function withdrawToken(address _tokenContract) public {
        IERC20 tokenContract = IERC20(_tokenContract);
        uint256 balance = tokenContract.balanceOf(address(this));
        uint256 remainingBalance = balance;
        require(remainingBalance > 0, "There is no token to withdraw.");
        for (uint8 i = 0; i < withdrawAddresses.length - 1; i++) {
            uint256 valueToTransfer = (perThousandPerAddress[i] * balance) /
                1000;
            tokenContract.transfer(withdrawAddresses[i], valueToTransfer);
            remainingBalance -= valueToTransfer;
        }
        tokenContract.transfer(
            withdrawAddresses[withdrawAddresses.length - 1],
            remainingBalance
        );
    }

    /** @dev Mint an NFT.*/
    function mint(uint16 numberToMint) public payable nonReentrant {
        require(
            numberToMint <= publicMaxMint,
            "You can't mint as much tokens at a time."
        );
        require(
            NFTsMinted + numberToMint <= NFTsLimit,
            "All NFTs have already been minted"
        );
        require(
            msg.value >= numberToMint * publicPrice,
            string(
                abi.encodePacked(
                    "You must send ",
                    Strings.toString(publicPrice),
                    " wei to mint a token."
                )
            )
        );
        require(
            balanceOf(msg.sender) + numberToMint <= publicMaxOwned,
            "You already have max tokens you can mint."
        );
        for (uint256 index = 0; index < numberToMint; index++) {
            NFTsMinted += 1;
            _safeMint(msg.sender, NFTsMinted);
        }
    }

    /** @dev Mint an NFT.*/
    function mintForFree(uint16 numberToMint) public nonReentrant {
        require(
            numberToMint <= whitelistMaxMint,
            "You can't mint as many tokens at a time."
        );
        require(
            NFTsMinted + numberToMint <= NFTsLimit,
            "All NFTs have already been minted."
        );
        require(
            balanceOf(msg.sender) + numberToMint <= whitelistMaxOwned,
            "You aready have more token than you can mint."
        );
        require(canMintForFree[msg.sender]);
        for (uint256 index = 0; index < numberToMint; index++) {
            NFTsMinted += 1;
            _safeMint(msg.sender, NFTsMinted);
        }
    }

    /** @dev Mint an NFT for whitelisted.*/
    function mintWhitelist(uint16 numberToMint) public payable nonReentrant {
        require(
            numberToMint <= whitelistMaxMint,
            "You can't mint as many tokens at a time."
        );
        require(
            NFTsMinted + numberToMint <= NFTsLimit,
            "All NFTs have already been minted."
        );
        require(isWhitelisted[msg.sender], "You're not whitelisted.");
        require(
            msg.value >= numberToMint * whitelistPrice,
            string(
                abi.encodePacked(
                    "You must send ",
                    Strings.toString(whitelistPrice),
                    " wei to mint a token."
                )
            )
        );
        require(
            balanceOf(msg.sender) + numberToMint <= whitelistMaxOwned,
            "You aready have more token than you can mint."
        );
        for (uint256 index = 0; index < numberToMint; index++) {
            NFTsMinted += 1;
            _safeMint(msg.sender, NFTsMinted);
        }
    }

    /** @dev add in whitelist.*/
    function addWhitelist(address toWhitelist) external onlyOwner {
        isWhitelisted[toWhitelist] = true;
    }

    /** @dev remove of whitelist.*/
    function removeWhitelist(address toWhitelist) external onlyOwner {
        isWhitelisted[toWhitelist] = false;
    }

    /** @dev add in mint for free.*/
    function addMintForFree(address toWhitelist) external onlyOwner {
        canMintForFree[toWhitelist] = true;
    }

    /** @dev remove of whitelist.*/
    function removeMintForFree(address toWhitelist) external onlyOwner {
        canMintForFree[toWhitelist] = false;
    }

    /** @dev reveal tokens by setting the correct baseURI.*/
    function revealNFTs() external onlyOwner {
        isRevealed = true;
    }
}