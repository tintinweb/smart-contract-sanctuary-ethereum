// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

interface IFansiCollectionNFT {
    function balanceOf(address _owner) external view returns (uint256);

    function balanceOf(address _owner, uint256 _id)
        external
        view
        returns (uint256);
}

contract FansiCollectionNFT is
    ERC721,
    Ownable,
    ReentrancyGuard,
    ERC721Enumerable
{
    string public baseTokenURI;
    string public subTokenURI;
    bool public isPaused = false;
    mapping(address => bool) public admins;

    //Project Setting
    struct Project {
        uint256 supply;
        uint256 maxSupply;
        uint256 dropsClaimed;
        uint256 totalDrops;
        uint256 maxPurchase;
        uint256 startSaleTime;
        uint256 endSaleTime;
        string projectURI;
        uint256 price; //in wei - 10 ** 18
    }

    mapping(uint256 => Project) public projectInfo;

    struct TokenInfo {
        uint256 projectId;
        uint256 editionId;
    }

    mapping(uint256 => TokenInfo) public tokenInfo;

    struct DiscountInfo {
        address contracts;
        uint256 price;
        uint8 type721;
        uint256 tokenId;
    }

    mapping(uint256 => DiscountInfo[]) public discountContract;

    struct AirDropInfo {
        address account;
        uint8 dropNum;
    }

    mapping(uint256 => mapping(address => uint8)) public airDropList;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        string memory _subUri
    ) ERC721(_name, _symbol) {
        baseTokenURI = _uri;
        subTokenURI = _subUri;

        admins[_msgSender()] = true;
    }

    function publicSale(uint256 _projectId, uint8 _purchaseNum)
        external
        payable
        nonReentrant
    {
        require(!isPaused, "FCNFT: currently paused");
        require(_msgSender() == tx.origin, "FCNFT: no contract mint");
        require(
            block.timestamp >= projectInfo[_projectId].startSaleTime,
            "FCNFT: publicSale is not open"
        );
        require(
            block.timestamp < projectInfo[_projectId].endSaleTime,
            "FCNFT: publicSale is ended"
        );

        require(
            _purchaseNum <= projectInfo[_projectId].maxPurchase,
            "FCNFT: reached max purchase"
        );
        require(
            (projectInfo[_projectId].supply + _purchaseNum) <=
                (projectInfo[_projectId].maxSupply),
            "FCNFT: reached max supply"
        );

        (, uint256 tokenPrice_) = getPrice(_projectId);

        require(
            msg.value >= (tokenPrice_ * _purchaseNum),
            "FCNFT: price is incorrect"
        );

        for (uint8 i = 0; i < _purchaseNum; i++) {
            uint256 currentNumber = totalSupply() + 1;
            uint256 currentEditionId = projectInfo[_projectId].supply +
                projectInfo[_projectId].dropsClaimed +
                1;
            _safeMint(
                _msgSender(),
                currentNumber,
                _projectId,
                currentEditionId
            );
            projectInfo[_projectId].supply++;
            tokenInfo[currentNumber].projectId = _projectId;
            tokenInfo[currentNumber].editionId = currentEditionId;
        }
    }

    function ownerMInt(
        address _addr,
        uint256 _projectId,
        uint8 _amount
    ) external onlyOwner {
        require(
            (projectInfo[_projectId].supply + _amount) <=
                (projectInfo[_projectId].maxSupply),
            "FCNFT: reached max supply"
        );

        for (uint8 i = 0; i < _amount; i++) {
            uint256 currentNumber = totalSupply() + 1;
            uint256 currentEditionId = projectInfo[_projectId].supply +
                projectInfo[_projectId].dropsClaimed +
                1;
            _safeMint(_addr, currentNumber, _projectId, currentEditionId);
            projectInfo[_projectId].supply++;
            tokenInfo[currentNumber].projectId = _projectId;
            tokenInfo[currentNumber].editionId = currentEditionId;
        }
    }

    function claimAirdrop(uint256 _projectId) external onlyAirDrop(_projectId) {
        require(
            block.timestamp >= projectInfo[_projectId].startSaleTime,
            "FCNFT: publicSale is not open"
        );

        for (uint8 i = 0; i < airDropList[_projectId][_msgSender()]; i++) {
            uint256 currentNumber = totalSupply() + 1;
            uint256 currentEditionId = projectInfo[_projectId].supply +
                projectInfo[_projectId].dropsClaimed +
                1;
            _safeMint(
                _msgSender(),
                currentNumber,
                _projectId,
                currentEditionId
            );
            projectInfo[_projectId].dropsClaimed++;
            tokenInfo[currentNumber].projectId = _projectId;
            tokenInfo[currentNumber].editionId = currentEditionId;
        }
        airDropList[_projectId][_msgSender()] = 0;
    }

    modifier onlyAdmin() {
        require(admins[_msgSender()], "FCNFT: caller is not admin");
        _;
    }

    modifier onlyAirDrop(uint256 _projectId) {
        require(
            airDropList[_projectId][_msgSender()] > 0,
            "FCNFT: caller not in AirdropList"
        );
        _;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseTokenURI = _baseURI;
    }

    function setSubURI(string memory _subURI) external onlyOwner {
        subTokenURI = _subURI;
    }

    function setProject(Project memory _projectInfo, uint256 _id)
        external
        onlyAdmin
        returns (bool)
    {
        projectInfo[_id].supply = _projectInfo.supply;
        projectInfo[_id].maxSupply = _projectInfo.maxSupply;
        projectInfo[_id].maxPurchase = _projectInfo.maxPurchase;
        projectInfo[_id].startSaleTime = _projectInfo.startSaleTime;
        projectInfo[_id].endSaleTime = _projectInfo.endSaleTime;
        projectInfo[_id].projectURI = _projectInfo.projectURI;
        projectInfo[_id].price = _projectInfo.price;

        return true;
    }

    function setMaxSupply(uint256 _projectId, uint256 _amount)
        external
        onlyAdmin
    {
        projectInfo[_projectId].maxSupply = _amount;
    }

    function setMaxPurchase(uint256 _projectId, uint256 _amount)
        external
        onlyAdmin
    {
        projectInfo[_projectId].maxPurchase = _amount;
    }

    function setStartSaleTime(uint256 _projectId, uint256 _time)
        external
        onlyAdmin
    {
        projectInfo[_projectId].startSaleTime = _time;
    }

    function setEndSaleTime(uint256 _projectId, uint256 _time)
        external
        onlyAdmin
    {
        projectInfo[_projectId].endSaleTime = _time;
    }

    function setProjectURI(uint256 _projectId, string memory _tokenURI)
        external
        onlyAdmin
    {
        projectInfo[_projectId].projectURI = _tokenURI;
    }

    function setPrice(uint256 _projectId, uint256 _price) external onlyAdmin {
        projectInfo[_projectId].price = _price;
    }

    function setDiscountContract(
        uint256 _projectId,
        DiscountInfo[] memory _contracts
    ) external onlyAdmin {
        delete discountContract[_projectId];
        for (uint8 i = 0; i < _contracts.length; i++) {
            discountContract[_projectId].push(_contracts[i]);
        }
    }

    function setAdminList(address _admin, bool _status)
        external
        onlyOwner
        returns (bool)
    {
        admins[_admin] = _status;

        return true;
    }

    function setPause(bool _isPaused) external onlyOwner returns (bool) {
        isPaused = _isPaused;

        return true;
    }

    function addBatchAirDropList(
        AirDropInfo[] memory _dropInfo,
        uint256 _projectId
    ) external onlyAdmin {
        for (uint256 i = 0; i < _dropInfo.length; i++) {
            airDropList[_projectId][_dropInfo[i].account] = _dropInfo[i]
                .dropNum;
            projectInfo[_projectId].totalDrops =
                projectInfo[_projectId].totalDrops +
                _dropInfo[i].dropNum;
        }
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function getPrice(uint256 _projectId)
        public
        view
        returns (address, uint256)
    {
        for (uint8 i = 0; i < discountContract[_projectId].length; i++) {
            if (discountContract[_projectId][i].type721 == 1) {
                try
                    IFansiCollectionNFT(
                        discountContract[_projectId][i].contracts
                    ).balanceOf(_msgSender())
                returns (uint256 _value) {
                    if (_value > 0) {
                        return (
                            discountContract[_projectId][i].contracts,
                            discountContract[_projectId][i].price
                        );
                    }
                } catch Error(string memory) {} catch (bytes memory) {}
            } else {
                try
                    IFansiCollectionNFT(
                        discountContract[_projectId][i].contracts
                    ).balanceOf(
                            _msgSender(),
                            discountContract[_projectId][i].tokenId
                        )
                returns (uint256 _value) {
                    if (_value > 0) {
                        return (
                            discountContract[_projectId][i].contracts,
                            discountContract[_projectId][i].price
                        );
                    }
                } catch Error(string memory) {} catch (bytes memory) {}
            }
        }

        return (address(0), projectInfo[_projectId].price);
    }

    function getDiscountContract(uint256 _projectId)
        external
        view
        returns (DiscountInfo[] memory)
    {
        return discountContract[_projectId];
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        uint256 projectId_ = tokenInfo[_tokenId].projectId;
        return
            bytes(projectInfo[projectId_].projectURI).length > 0
                ? string(
                    abi.encodePacked(
                        subTokenURI,
                        projectInfo[projectId_].projectURI,
                        Strings.toString(tokenInfo[_tokenId].editionId),
                        ".json"
                    )
                )
                : string(
                    abi.encodePacked(baseTokenURI, Strings.toString(_tokenId))
                );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
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