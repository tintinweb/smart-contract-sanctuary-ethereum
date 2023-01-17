// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./EnumerableSet.sol";
import "./ERC721Burnable.sol";

contract ExerciseSupplementNFT is ERC721, Ownable, ERC721Burnable{
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    string public baseURI;
    string public baseExtension = ".json";
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private admins;
    EnumerableSet.AddressSet private listNftAddress;
    EnumerableSet.AddressSet private listERC20Address;
    EnumerableSet.AddressSet private listSpecialNftAddress;
    address public donationWalletAddress; 
    mapping(address => bool) public typeNfts;

    modifier onlyAdmin() {
        require(admins.contains(_msgSender()), "NOT ADMIN");
        _;
    }

    constructor(
        string memory _initBaseURI
    ) ERC721("ExerciseSupplementNFT", "ESPLNFT") {
        setBaseURI(_initBaseURI);
        admins.add(msg.sender);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function safeMint(address to) public payable {
        require(_msgSender().code.length > 0 || admins.contains(_msgSender()), 
            "Address can't mint NFT"
        );
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function nextTokenIdToMint() public view returns(uint256) {
        return _tokenIdCounter.current();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function updateNftListAddress(address _nftAddress, bool _flag, bool _isTypeErc721) external onlyAdmin {
        require(_nftAddress != address(0), "INVALID NFT ADDRESS");
        if (_flag) {
            listNftAddress.add(_nftAddress);
        } else {
            listNftAddress.remove(_nftAddress);
        }
        typeNfts[_nftAddress] = _isTypeErc721;
    }

    function updateListERC20Address(address _erc20Address, bool _flag) external onlyAdmin {
        require(_erc20Address != address(0), "INVALID NFT ADDRESS");
        if (_flag) {
            listERC20Address.add(_erc20Address);
        } else {
            listERC20Address.remove(_erc20Address);
        }
    }

    function updateSpecialNftAddress(address _nftAddress, bool _flag) external onlyAdmin {
        require(_nftAddress != address(0), "INVALID NFT ADDRESS");
        if (_flag) {
            listSpecialNftAddress.add(_nftAddress);
        } else {
            listSpecialNftAddress.remove(_nftAddress);
        }
    }

    function updateAdmin(address _adminAddr, bool _flag) external onlyAdmin {
        require(_adminAddr != address(0), "INVALID ADDRESS");
        if (_flag) {
            admins.add(_adminAddr);
        } else {
            admins.remove(_adminAddr);
        }
    }

    function updateDonationWalletAddress(address _donationWalletAddress) external onlyAdmin {
        require(_donationWalletAddress != address(0), "INVALID ADDRESS");
        donationWalletAddress = _donationWalletAddress;
    }

    function getAdmins() external view returns (address[] memory) {
        return admins.values();
    }
 
    function getNftListAddress() external view returns (address[] memory) {
        return listNftAddress.values();
    }

    function getErc20ListAddress() external view returns (address[] memory) {
        return listERC20Address.values();
    }

    function getSpecialNftAddress() external view returns (address[] memory) {
        return listSpecialNftAddress.values();
    }
}