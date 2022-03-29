// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract Craft is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 public tokenPrice = 0.2 ether;
    uint256 public maxToken = 10000;
    uint256 public maxMint = 2;
    bool internal lockBaseUri = false;

    mapping(address => uint256) internal mintCount;
    mapping(address => bool) internal whiteList;
    address[] internal whiteListArr;
    bool internal preSaleIsActive = false;
    bool internal saleIsActive = false;

    uint256 public currentSupply;
    string internal baseURI;

    constructor(string memory baseURI_) ERC721("Craft", "Craft") {
        baseURI = baseURI_;
    }

    // 배이스URI 오버라이드
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // 배이스URI 설정
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        require(!lockBaseUri, "no");
        baseURI = baseURI_;
    }

    // 배이스URI 락
    function setLockBaseUri() external onlyOwner {
        lockBaseUri = true;
    }

    // 화이트리스트 등록
    function setWhiteList(address[] memory _account) external onlyOwner {
        for (uint256 i = 0; i < _account.length; i++) {
            whiteList[_account[i]] = true;
            whiteListArr[i] = _account[i];
        }
    }

    // 에어드롭
    function airDrop(address[] memory _accounts) external payable onlyOwner {
        for (uint i=0; i < _accounts.length; i++) {
            _safeMint(_accounts[i], currentSupply++);
        }
    }

    // 1차민팅
    function preMint() external payable {
        require(whiteList[msg.sender], "no"); // 화이트리스트 체크
        require(preSaleIsActive, "no"); // 판매상태 체크
        require(totalSupply().add(1) <= maxToken, "no"); // 민팅수량 체크
        _safeMint(msg.sender, currentSupply++); // 민팅후 현재수량 증가
        whiteList[msg.sender] = false; // 화이트리스트 등록 취소
    }

    // 2차민팅
    function mint() external payable {
        require(mintCount[msg.sender] < maxMint, "no"); // 2차민팅 횟수가 maxMint 미만일 경우
        require(saleIsActive, "no"); // 판매상태 체크
        require(totalSupply().add(1) <= maxToken, "no"); // 민팅수량 체크
        _safeMint(msg.sender, currentSupply++);
        mintCount[msg.sender]++;
    }

    // 민팅횟수 설정
    function setMaxMinting(uint256 _maxMint) external onlyOwner {
        maxMint = _maxMint;
    }

    // 총 민팅된 NFT수량
    function totalSupply() public view returns (uint256) {
        return currentSupply;
    }

    // 토큰가격 설정
    function setTokenPrice(uint256 _tokenPrice) public onlyOwner() {
        tokenPrice = _tokenPrice;
    }

    // 세일상태를 변경하는 함수
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }
    // 프리세일상태를 변경하는 함수
    function flipPreSaleState() external onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    // 이더 다른지갑으로 전송
    function withdraw(uint256 _amount) external payable onlyOwner {
        require(payable(msg.sender).send(_amount));
    }

    // 이더 다른지갑으로 전송
    function withdrawAll() external payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    // 화이트리스트 배열 보기
    function getWhiteListAll() external view returns(address[] memory) {
        return whiteListArr;
    }
}