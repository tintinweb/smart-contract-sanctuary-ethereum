// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Counters.sol";

contract AstrologyClub is ERC721Enumerable, Ownable, PaymentSplitter {
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 public maxMintSupply = 10000;
    uint256 public totalMinted;

    string public baseURI;
    string public baseExtension = ".json";

    bool public publicState = false;

    uint256 _price = 100000000000000000; //0.1 ETH

    Counters.Counter private _tokenIds;

    uint256[] private _teamShares = [60, 33, 5, 2];

    address[] private _team = [
        0xBD584cE590B7dcdbB93b11e095d9E1D5880B44d9,
        0x85a37aC5C3250827B4f50F3373275c67C7f5fF3b,
        0xA26AE192f618F89F3579974E87e2a92770654605,
        0x1D7d6857c397788d1d33744276B54EfaE92CbBad
    ];

    constructor() ERC721("AstrologyClub", "ZODIAC") PaymentSplitter(_team, _teamShares) {
        _transferOwnership(_team[0]);
    }

    function enable() public onlyOwner {
        publicState = true;
    }

    function disable() public onlyOwner {
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

    function mint(uint256 _amount) external payable {
        require(publicState, "mint disabled");

        require(_amount > 0, "zero amount");
        require(_amount <= 30, "can't mint so much tokens");

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

}