// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Counters.sol";

interface IExternalContract {
    function balanceOf(address owner) external view returns (uint256);
}

contract RichApesClub is ERC721A, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 immutable price = 77700000000000000; //0.0777 ETH

    uint256 public maxMintSupply = 4444;
    uint256 public limitPerWallet = 20;

    bool public publicState = true;

    string public baseURI;

    address public externalContractAddress;

    mapping(address => bool) public _claimed;

    constructor()
        ERC721A("RichApesClub", "RAC", limitPerWallet, maxMintSupply) {
        _transferOwnership(0xBD584cE590B7dcdbB93b11e095d9E1D5880B44d9);
        externalContractAddress = 0xe62a9Ed27708698cfD5Eb95310d0010953843B13;
        baseURI = "ipfs://QmcZAavfLTUExY4iUdN5hMuyWo6GEUXXxZ2jFo2cbps4yP/";
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

    function setExternalContractAddress(address contractAddress) external onlyOwner {
        externalContractAddress = contractAddress;
    }

    function externalBalanceOf(address owner) public view returns (uint256) {
        return IExternalContract(externalContractAddress).balanceOf(owner);
    }

    function mint(uint256 _amount) external payable {
        require(publicState, "mint disabled");
        require(_amount > 0, "zero amount");
        require(msg.value >= (price * _amount), "value sent is not correct");
        require(totalSupply() + _amount <= maxMintSupply, "max supply exceeded");

       _safeMint(_msgSender(), _amount);
    }

    function claim() external payable {
        require(publicState, "mint disabled");

        uint256 extBalance = externalBalanceOf(_msgSender());
        require(extBalance > 0, "nothing to claim");
        require(!_claimed[_msgSender()], "already claimed");
        require(totalSupply() + extBalance <= maxMintSupply, "max supply exceeded");

        _safeMint(_msgSender(), extBalance);
        _claimed[_msgSender()] = true;
    }

    function withdraw() public onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}