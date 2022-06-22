// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import './ERC2981ContractWideRoyalties.sol';

contract Windbags is ERC721Enumerable, Ownable, ERC2981ContractWideRoyalties {

    using SafeMath for uint256;
    using Address for address;

    uint256 public constant _PRICE = 0.05 ether;

    address public _PAYOUT_RECEIVER;
    string private baseURI;

    bool public presaleActive = false;
    bool public saleActive = false;

    uint256 public presaleSupply;
    uint256 public maxSupply;
    
    mapping (address => uint256) public presaleWhitelist;

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
    ) ERC721("Windbags", "WB") {
        presaleSupply = _presaleSupply;
        maxSupply = _maxSupply;
        _setRoyalties(address(_royaltyReceiver), _royalty);
        _PAYOUT_RECEIVER = address(_payoutReceiver);
    }

    function mint() public payable {
        require(presaleActive || saleActive,        "Presale/Sale must be active to mint");
        require(_PRICE == msg.value,                "Ether value sent is not correct");
        require(totalSupply().add(1) <= maxSupply,  "Purchase would exceed max supply");

        uint256 _tokenId = totalSupply() + 1;

        if (presaleActive && !saleActive) {
            require(presaleWhitelist[msg.sender] > 0,       "No tokens reserved for this address");
            require(totalSupply().add(1) <= presaleSupply,  "Purchase would exceed presale supply");
            presaleWhitelist[msg.sender] = 0;
        }

        _safeMint(msg.sender, _tokenId);
    }

    function editWhitelist(address[] calldata presaleAddresses) public onlyOwner {
        for(uint256 i; i < presaleAddresses.length; i++){
            presaleWhitelist[presaleAddresses[i]] = 1;
        }
    }

    function withdraw() public {
        require(msg.sender == _PAYOUT_RECEIVER, "Sender is not the payout receiver");
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
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

    function airdrop(address receiver) public onlyOwner {
        require(totalSupply().add(1) <= maxSupply,  "Purchase would exceed max supply");

        uint256 _tokenId = totalSupply() + 1;
        _safeMint(receiver, _tokenId);
    }
}