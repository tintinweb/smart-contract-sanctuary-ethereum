// SPDX-License-Identifier: MIT
// Contract based on https://docs.openzeppelin.com/contracts
pragma solidity ^0.8.7;
/**
 * @version 0.2.4
 */
// -- -- --
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Brave108Cats is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    mapping(uint256 => string) private _tokenURIs;
    mapping(address => bool) private _moders;

    bool public _isSaleActive = false;
    bool public _isMinterMintActive = false;

    address public minter;

    // Constants
    // #UPDATE
    uint256 public constant MAX_SUPPLY = 256;

    uint256 public tierSupply = 2;
    uint256 public maxBalance = 3;
    uint256 public maxMint = 1;
    // EOF

    string public baseExtension = ".json";
    string private _baseURIExtended;

    event TokenMinted(uint256 supply);

    constructor() ERC721("108 Cats", "108CATS") {
        _moders[msg.sender] = true;
    }

    modifier onlyModer() {
        require(
            _moders[msg.sender] == true,
            "onlyModer: Caller Can Only Be One of Moders"
        );
        _;
    }

    modifier onlyMinter() {
        require(
            msg.sender == minter,
            "onlyMinter: Caller Can Only Be The Minter"
        );
        _;
    }

    function filpSaleActive() public onlyOwner {
        _isSaleActive = !_isSaleActive;
    }

    function filpMinterMintActive() public onlyOwner {
        _isMinterMintActive = !_isMinterMintActive;
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    function setTierSupply(uint256 _tierSupply) public onlyOwner {
        tierSupply = _tierSupply;
    }

    function setMaxBalance(uint256 _maxBalance) public onlyOwner {
        maxBalance = _maxBalance;
    }

    function setMaxMint(uint256 _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }

    function withdraw(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }

    function ownerMint(address to, uint256 quantity) public onlyOwner {
        require(
            totalSupply() + quantity <= tierSupply,
            "ownerMint: Exceeds Tier Supply"
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "ownerMint: Exceeds Max Supply"
        );

        require(
            balanceOf(to) + quantity <= maxBalance,
            "ownerMint: Exceeds Max Balance"
        );

        _bake(to, quantity);
        emit TokenMinted(totalSupply());
    }

    function minterMint(address to, uint256 quantity) external onlyMinter {
        require(_isMinterMintActive, "Minter Mint Must be Active");
        require(
            totalSupply() + quantity <= tierSupply,
            "minterMint: Exceeds Tier Supply"
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "minterMint: Exceeds Max Supply"
        );

        require(
            balanceOf(to) + quantity <= maxBalance,
            "minterMint: Exceeds Max Balance"
        );

        require(quantity <= maxMint, "minterMint: Exceeds Max Mint");

        _bake(to, quantity);
        emit TokenMinted(totalSupply());
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply();
    }

    function getTokensByOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function _bake(address recipient, uint256 quantity) internal {
        uint256 supply = totalSupply();
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(recipient, supply + i);
        }
    }

    function setBaseURI(string memory baseURI_) external onlyModer {
        _baseURIExtended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function setTokenURIStorage(uint256 tokenId, string memory _tokenURI)
        public
        onlyModer
    {
        require(
            _exists(tokenId),
            "setTokenURIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function unsetTokenURIStorage(uint256 tokenId) public onlyModer {
        require(
            _exists(tokenId),
            "unsetTokenURIStorage: URI unset of nonexistent token"
        );
        require(
            bytes(_tokenURIs[tokenId]).length != 0,
            "unsetTokenURIStorage: No URI storage set"
        );

        delete _tokenURIs[tokenId];
    }

    function addModer(address _moder) external onlyOwner {
        _moders[_moder] = true;
    }

    function removeModer(address _moder) external onlyOwner {
        require(_moder != owner(), "removeModer: Can not remove owner");
        delete _moders[_moder];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "tokenURI: Nonexistent Token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_tokenURI));
        }

        return _enumerableTokenURI(tokenId);
    }

    function _enumerableTokenURI(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(_baseURI(), tokenId.toString(), baseExtension)
            );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}