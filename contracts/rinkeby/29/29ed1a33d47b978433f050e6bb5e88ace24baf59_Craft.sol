// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract Craft is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 public tokenPrice = 0.2 ether; // NFT 민팅 가격
    uint256 public preTokenMax = 3800; // 프리세일에 판매하는 NFT의 최대 수
    uint256 public maxToken = 1;
    address[] public whiteList;
    uint256 public whiteListNum;
    // uint256 public maxMint = 6000; // 하나의 지갑으로 민팅할 수 있는 최대 NFT개 수

    // uint256 public saleTokenMax = 10000; // 세일에 판매하는 NFT의 최대 수

    uint256 public currentSupply; // 현재까지 민팅된 NFT 수
    // string public baseTokenURI; // 배이스 토큰 URI
    // bool public saleIsActive = false; // 세일상태
    // bool public preSaleIsActive = false; // 프리세일 판매 상태

    // mapping(uint256 => uint256) _tokens;
    // mapping(uint256 => bool) private itemIds;

    constructor(string memory _baseTokenURI) ERC721("Craft", "Craft") {
        // setBaseURI(_baseTokenURI);
    }

    // function setWhiteList(address[] memory _account) external onlyOwner {
    //     for(uint256 i = 0; i < 1000; i++) {
    //         whiteList.push(_account[0]);
    //         whiteListNum++;
    //     }
    // }

    // function mintTest() external payable onlyOwner {
    //     for (uint256 i = 0; i < whiteList.length; i++) { // 민트를 호출한 지갑에 어마운트만큼 민트실행 후 currentSupply + 1
    //         _safeMint(whiteList[i], currentSupply++);
    //     }
    // }

    function mint1(address[] memory _account) external payable onlyOwner {
        for (uint256 i = 0; i < _account.length; i++) {
            _safeMint(_account[i], currentSupply++);
        }
    }

    function mint2(address _account) external payable onlyOwner {
        for (uint256 i = 0; i < 10; i++) {
            _safeMint(_account, currentSupply++);
        }
    }

    //     function preMint(address _to, uint256 amount) external payable {
    //         require(saleIsActive, "Sale must be active to mint Item"); // 세일상태가 false이면 에러
    //         require(totalSupply().add(amount) <= preTokenMax, "Exceed max supply limit."); // 프리세일에 판매가능한 수량 이상 민팅 되었을 시 오류
    //         require(amount <= maxMint, "Only 3 can mint."); // 한번에 민트 할 수 있는 NFT의 수가 맥스민트 이상일 시 에러
    //         require(tokenPrice.mul(amount) <= msg.value, "Ether sent is not correct"); // 보낸 이더의 값이 토큰프라이스 * amount의의 값과 다르면 오류
    //         for (uint256 i = 0; i < amount; i++) { // 민트를 호출한 지갑에 어마운트만큼 민트실행 후 currentSupply + 1
    //             _safeMint(_to, currentSupply++);
    //         }
    //     }

    //     function mint(address _to, uint256 amount) external onlyOwner {
    //         require(saleIsActive, "Sale must be active to mint Item"); // 세일상태가 false이면 에러
    //         require(totalSupply().add(amount) <= saleTokenMax, "Exceed max supply limit."); // 세일에 판매가능한 수량 이상 민팅 되었을 시 오류
    //         require(amount <= maxMint, "Only 3 can mint."); // 한번에 민트 할 수 있는 NFT의 수가 맥스민트 이상일 시 에러
    //         for (uint256 i = 0; i < amount; i++) {
    //             _safeMint(_to, currentSupply++);
    //         }
    //     }

    //     function totalSupply() public view returns (uint256) {
    //         return currentSupply;
    //     }

    //     function existsItemId(uint256 itemId) public view returns (bool){
    //         return itemIds[itemId];
    //     }

    //     function encodeTest(uint256 number) public view returns (uint256[] memory) {
    //         uint256[] memory metadata = new uint256[](maxToken);
    //         for (uint256 i = 0; i < maxToken; i += 1) {
    //             metadata[i] = i;
    //         }
    //         for (uint256 i = 0; i < maxToken; i += 1) {
    //             uint256 j = (uint256(keccak256(abi.encode(number, i))) % (maxToken));
    //             if(j>0 && j< maxToken) {
    //                 (metadata[i], metadata[j]) = (metadata[j], metadata[i]);
    //             }
    //         }
    //         return metadata;
    //     }

    //     function getMetadata(uint256 tokenId) public view returns (string memory) {
    //         if (_msgSender() != owner()) {
    //             require(tokenId < totalSupply(), "Token not exists.");
    //         }
    //         uint256[] memory result = new uint256[](maxToken);
    //         for (uint256 i = 0; i < maxToken; i += 1) {
    //             result[i] = i;
    //         }
    //         for (uint256 i = 0; i < maxToken; i += 1) {
    //             uint256 j = (uint256(keccak256(abi.encode(seed, i))) % (maxToken));
    //             if(j > 0 && j < maxToken) {
    //                 (result[i], result[j]) = (result[j], result[i]);
    //             }
    //         }
    //         return Strings.toString(result[tokenId]);
    //     }

    //     function tokenURI(uint256 tokenId) public view override returns (string memory) {
    //         require(tokenId < totalSupply(), "Token not exist.");
    //         return string(abi.encodePacked(baseTokenURI, getMetadata(tokenId), ".json"));
    //     }

    //     function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
    //         uint256 tokenCount = balanceOf(_owner);
    //         if (tokenCount == 0) {
    //             return new uint256[](0);
    //         } else {
    //             uint256[] memory result = new uint256[](tokenCount);
    //             uint256 index = 0;
    //             for (uint i = 0; i < currentSupply; i++) {
    //                 if (ownerOf(i) == _owner) {
    //                     result[index] = _tokens[i];
    //                     index++;
    //                 }
    //                 if (index == tokenCount) break;
    //             }
    //             return result;
    //         }
    //     }

    //     function setTokenPrice(uint256 _tokenPrice) public onlyOwner() {
    //         tokenPrice = _tokenPrice;
    //     }

    //     function setBaseURI(string memory _baseTokenURI) public onlyOwner {
    //         baseTokenURI = _baseTokenURI;
    //     }

    //     function flipSaleState() external onlyOwner {
    //         saleIsActive = !saleIsActive;
    //     }

    //     function flipPreSaleState() external onlyOwner {
    //         preSaleIsActive = !preSaleIsActive;
    //     }

    //     function withdraw(uint256 _amount) public payable onlyOwner {
    //         require(payable(msg.sender).send(_amount));
    //     }

    //     function withdrawAll() public payable onlyOwner {
    //         require(payable(msg.sender).send(address(this).balance));
    //     }

    //     function _baseURI() internal view virtual override returns (string memory) {
    //         return baseTokenURI;
    //     }
}