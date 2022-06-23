// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC2981ContractWideRoyalties.sol";

//import "hardhat/console.sol";

contract SacredPanther is
    ERC721Enumerable,
    Ownable,
    ERC2981ContractWideRoyalties
{
    using SafeMath for uint256;
    using Address for address;

    uint256 public constant _PRICE = 0.2 ether;

    address public _PAYOUT_RECEIVER;
    string private baseURI;

    bool public presaleActive = false;
    bool public saleActive = false;

    uint256 public presaleSupply;
    uint256 public maxSupply;

    mapping(address => uint256) public presaleWhitelist;

    event revealed(string _baseURI);

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    constructor(
        uint256 _presaleSupply,
        uint256 _maxSupply,
        uint256 _royalty,
        address _royaltyReceiver,
        address _payoutReceiver
    ) ERC721("Sacred Panther", "SP") {
        presaleSupply = _presaleSupply;
        maxSupply = _maxSupply;
        _setRoyalties(address(_royaltyReceiver), _royalty);
        _PAYOUT_RECEIVER = address(_payoutReceiver);
    }

    function mint(uint256 tokenId) public payable {
        require(
            presaleActive || saleActive,
            "Presale/Sale must be active to mint"
        );
        require(_PRICE == msg.value, "Ether value sent is not correct");
        require(tokenId > 0, "TokenId cannot be 0");
        require(tokenId <= maxSupply, "TokenId cannot exceed max supply");

        if (presaleActive && !saleActive) {
            require(
                presaleWhitelist[msg.sender] > 0,
                "No tokens reserved for this address"
            );
            require(
                totalSupply().add(1) <= presaleSupply,
                "Purchase would exceed presale supply"
            );
            presaleWhitelist[msg.sender] = 0;
        }

        _safeMint(msg.sender, tokenId);
    }

    function editWhitelist(address[] calldata presaleAddresses)
        public
        onlyOwner
    {
        for (uint256 i; i < presaleAddresses.length; i++) {
            presaleWhitelist[presaleAddresses[i]] = 1;
        }
    }

    function withdraw() public {
        require(
            msg.sender == _PAYOUT_RECEIVER,
            "Sender is not the payout receiver"
        );
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Withdraw failed");
    }

    function togglePresale() public onlyOwner {
        presaleActive = !presaleActive;
    }

    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
        emit revealed(uri);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setPayoutReceiver(address addr) public onlyOwner {
        _PAYOUT_RECEIVER = addr;
    }

    function setRoyalties(address recipient, uint256 value) public onlyOwner {
        _setRoyalties(recipient, value);
    }

    function airdrop(address receiver, uint256 tokenId) public onlyOwner {
        require(tokenId <= maxSupply, "TokenId cannot exceed max supply");
        require(tokenId > 0, "TokenId cannot be 0");

        _safeMint(receiver, tokenId);
    }
}