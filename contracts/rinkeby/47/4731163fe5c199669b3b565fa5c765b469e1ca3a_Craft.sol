// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract Craft is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 public tokenPrice = 0.001 ether; // 토큰가격
    uint256 public maxToken = 10000; // 총 발행될 토큰 수

    uint256 public maxMint = 2; // 지갑당 민트횟수(화이트리스트 제외)
    uint256 public currentSupply; // 현재까지 민팅된 토큰 수
    mapping(address => uint256) public mintCount; // 민트한 횟수
    mapping(address => bool) public whiteList; // 화이트리스트 민팅 상태()
    address[] public whiteListArr; // 화이트리스트 지갑주소 배열
    bool public preSaleIsActive = false; // 프리세일 오픈상태
    bool public saleIsActive = false; // 세일 오픈상태
    bool public setBaseUriKey = true; // setBaseURI 키
    string public baseURI; // baseURI

    constructor(string memory baseURI_) ERC721("Craft", "Craft") {
        baseURI = baseURI_;
    }

    // _baseURI를 baseURI로 설정
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // baseURI를 baseURI_로 설정
    function setBaseURI(string memory baseURI_) external onlyOwner {
        require(setBaseUriKey, "no");
        baseURI = baseURI_;
    }

    // 배이스URI 락
    function setLockBaseUri() external onlyOwner {
        setBaseUriKey = false;
    }

    // _account 배열을 반복하여 화이트리스트 등록
    function setWhiteList(address[] memory _account) external onlyOwner {
        for (uint256 i = 0; i < _account.length; i++) {
            whiteList[_account[i]] = true;
            whiteListArr.push(_account[i]);
        }
    }

    // 에어드롭
    function airDrop(address[] memory _accounts) external payable onlyOwner {
        require(totalSupply().add(_accounts.length) <= maxToken, "no");
        for (uint i=0; i < _accounts.length; i++) {
            _safeMint(_accounts[i], currentSupply++);
        }
    }

    // 화이트리스트 민팅
    function preMint() external payable {
        require(totalSupply().add(1) <= maxToken, "no"); // 민팅수량 체크 1~10000
        require(whiteList[msg.sender], "no"); // 화이트리스트 체크
        require(preSaleIsActive, "no"); // 판매상태 체크
        require(msg.value == tokenPrice, "no"); // 가격 확인
        _safeMint(msg.sender, currentSupply + 1); // 민팅후
        currentSupply++; // 현재수량 증가
        whiteList[msg.sender] = false; // 화이트리스트 등록 취소
    }

    // 민팅
    function mint() external payable {
        require(totalSupply().add(1) <= maxToken, "no"); // 민팅수량 체크 1~10000
        require(mintCount[msg.sender] < maxMint, "no"); // 2차민팅 횟수가 maxMint 미만일 경우
        require(saleIsActive, "no"); // 판매상태 체크
        require(msg.value == tokenPrice, "no"); // 가격 확인
        _safeMint(msg.sender, currentSupply + 1);
        currentSupply++;
        mintCount[msg.sender]++;
    }

    // 민팅횟수 설정
    function setMaxMint(uint256 _maxMint) external onlyOwner {
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
    function withdraw(address _account, uint256 _amount) external payable onlyOwner {
        require(payable(_account).send(_amount));
    }

    // 이더 다른지갑으로 전송
    function withdrawAll() external payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    // 화이트리스트인지 아닌지 확인 (웹에서 사용)
    function checkWhiteList() external view returns(bool) {
        return whiteList[msg.sender];
    }

    // 화이트리스트 배열 보기
    function getWhiteListAll() external view returns(address[] memory) {
        return whiteListArr;
    }
}