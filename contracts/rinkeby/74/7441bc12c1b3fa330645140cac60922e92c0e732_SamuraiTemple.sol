// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./MerkleProof.sol";

//  
// ,---.                         o--.--               |         
// `---.,---.,-.-..   .,---.,---..  |  ,---.,-.-.,---.|    ,---.
//     |,---|| | ||   ||    ,---||  |  |---'| | ||   ||    |---'
// `---'`---^` ' '`---'`    `---^`  `  `---'` ' '|---'`---'`---'
//
contract SamuraiTemple is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 public maxMintSupply = 10000;
    uint256 public totalMinted;

    uint256 presaleMintLimit = 3;

    string public baseURI;
    string public baseExtension = ".json";

    bool public publicState = false;
    bool public presaleState = false;

    mapping(address => uint256) public _presaleClaimed;

    uint256 _price = 60000000000000000; //0.06 ETH

    bytes32 public presaleRoot;

    Counters.Counter private _tokenIds;

    constructor() ERC721("SamuraiTemple", "SMTP") {}

    function enablePresale(bytes32 _presaleRoot) public onlyOwner {
        presaleState = true;
        presaleRoot = _presaleRoot;
    }

    function enablePublic() public onlyOwner {
        presaleState = false;
        publicState = true;
    }

    function disable() public onlyOwner {
        presaleState = false;
        publicState = false;
    }

    function setBaseURI(string calldata _tokenBaseURI) external onlyOwner {
        baseURI = _tokenBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "nonexistent token");
        string memory base = _baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base,tokenId.toString(),baseExtension)) : "";
    }

    /**
     * Presale Mint, allows you to mint nft but you need to provide merkle proof,
     * see function verify().
     */
    function mint(uint256 _amount, bytes32[] memory proof) external payable {
        require(presaleState, "presale disabled");
        require(!publicState, "presale disabled");

        require(
            totalMinted + _amount <= maxMintSupply,
            "max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "value sent is not correct"
        );
        require(
            _presaleClaimed[msg.sender] + _amount <= presaleMintLimit,
            "can't mint such a amount"
        );
        require(verify(msg.sender, proof), "not selected for the presale");

        for (uint256 ind = 0; ind < _amount; ind++) {
            _tokenIds.increment();
            _safeMint(msg.sender, _tokenIds.current());
            _presaleClaimed[msg.sender] = _presaleClaimed[msg.sender] + 1;
            totalMinted = totalMinted + 1;
        }
    }

    function mint(uint256 _amount) external payable {
        require(publicState, "mint disabled");

        require(_amount > 0, "zero amount");
        require(_amount <= 3, "can't mint so much tokens");

        require(
            totalMinted + _amount <= maxMintSupply,
            "max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "value sent is not correct"
        );
        for (uint256 ind = 0; ind < _amount; ind++) {
            _tokenIds.increment();
            _safeMint(msg.sender, _tokenIds.current());
            totalMinted = totalMinted + 1;
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function verify(address account, bytes32[] memory proof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        return MerkleProof.verify(proof, presaleRoot, leaf);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

}