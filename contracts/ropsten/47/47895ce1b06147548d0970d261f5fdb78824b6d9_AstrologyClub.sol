// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Counters.sol";

contract AstrologyClub is ERC721A, Ownable, PaymentSplitter {
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 public maxMintSupply = 10000;
    uint256 public limitPerWallet = 500;
    uint256 public totalMinted;

    string public baseURI;

    bool public publicState = false;

    uint256 immutable price = 100000000000000000; //0.1 ETH

    uint256[] private _teamShares = [60, 33, 5, 2];

    address[] private _team = [
        0xBD584cE590B7dcdbB93b11e095d9E1D5880B44d9,
        0x85a37aC5C3250827B4f50F3373275c67C7f5fF3b,
        0xA26AE192f618F89F3579974E87e2a92770654605,
        0x1D7d6857c397788d1d33744276B54EfaE92CbBad
    ];

    constructor()
        ERC721A("AstrologyClub", "ZODIAC", limitPerWallet, maxMintSupply)
        PaymentSplitter(_team, _teamShares) {
        _transferOwnership(_team[0]);
        _safeMint(_team[0], 500);
    }

    function enable() public onlyOwner {
        publicState = true;
    }

    function disable() public onlyOwner {
        publicState = false;
    }

    function mint(uint256 _amount) external payable {
        require(publicState, "mint disabled");
        require(_amount > 0, "zero amount");
        require(_amount <= limitPerWallet, "can't mint so much tokens");
        require(totalSupply() + _amount <= maxMintSupply, "max supply exceeded");
        require(msg.value >= price * _amount , "value sent is not correct");

        _safeMint(_msgSender(), _amount);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

}