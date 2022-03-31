// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract Craft is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 public tokenPrice = 200000000000000000 wei;
    uint256 public totalToken = 10000;
    uint256 internal currentSupply;

    uint256 internal publicMintMax = 1;
    uint256 public publicTokenMax = 6500;
    uint256 public publicSupply;
    bool public publicSaleActive = false;
    mapping(address => uint256) public publicMintCount;

    uint256 internal preMintMax = 1;
    uint256 internal preTokenMax = 3000;
    uint256 public preSupply;
    bool public preSaleActive = false;
    uint256 public remainingToken;
    mapping(address => bool) internal preSaleTarget;
    mapping(address => uint256) internal preMintCount;

    bool public setBaseUriKey = true;
    string internal baseURI;

    constructor(string memory baseURI_) ERC721("Craft", "Craft") {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        require(setBaseUriKey, "Cannot change baseURI.");
        baseURI = baseURI_;
    }

    function setLockBaseUri() external onlyOwner {
        setBaseUriKey = false;
    }

    // 에어드롭
    function airDrop(address[] memory _accounts) external payable onlyOwner {
        require(totalSupply().add(_accounts.length * 5) <= totalToken, "no");
        for (uint i = 0; i < _accounts.length; i++) {
            for(uint j = 0; j < 5; j++) {
                _safeMint(_accounts[i], currentSupply+1);
                currentSupply++;
            }
        }
    }

    // 프리세일
    function flipPreSaleState() external onlyOwner {
        preSaleActive = !preSaleActive;
    }

    function setPreSaleTarget(address[] memory _account) external onlyOwner {
        for (uint256 i = 0; i < _account.length; i++) {
            preSaleTarget[_account[i]] = true;
        }
    }

    function preMint() external payable {
        require(preSaleActive, "Not for pre-sale yet.");
        require(preSupply < preTokenMax, "Pre-sale sold out.");
        require(preSaleTarget[msg.sender], "It is not a pre-sale target.");
        require(preMintCount[msg.sender] < preMintMax, "It is no longer available for purchase.");
        require(msg.value == tokenPrice, "You entered an incorrect amount.");
        _safeMint(msg.sender, currentSupply + 1);
        currentSupply++;
        preSupply++;
        preMintCount[msg.sender]++;
    }

    function setRemainingToken() external onlyOwner {
        require(!preSaleActive, "Pre-Sale still in progress");
        remainingToken = preTokenMax - preSupply;
    }

    // 퍼블릭 세일
    function flipPublicSaleState() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function mint() external payable {
        require(publicSaleActive, "Not for public-sale yet.");
        require(publicSupply < publicTokenMax + remainingToken, "Public-sale sold out.");
        require(publicMintCount[msg.sender] < publicMintMax, "It is no longer available for purchase.");
        require(msg.value == tokenPrice, "You entered an incorrect amount.");
        _safeMint(msg.sender, currentSupply + 1);
        currentSupply++;
        publicSupply++;
        publicMintCount[msg.sender]++;
    }

    // 세일 전 후 세팅
    function setPreMintMax(uint256 _preMintMax) external onlyOwner {
        preMintMax = _preMintMax;
    }

    function setPublicMintMax(uint256 _publicMintMax) external onlyOwner {
        publicMintMax = _publicMintMax;
    }

    function setTokenPrice(uint256 _tokenPrice) external onlyOwner() {
        tokenPrice = _tokenPrice;
    }

    function withdraw(address _account, uint256 _amount) external payable onlyOwner {
        require(payable(_account).send(_amount));
    }

    function withdrawAll(address _account) external payable onlyOwner {
        require(payable(_account).send(address(this).balance));
    }

    // 기능 함수
    function totalSupply() public view returns (uint256) {
        return currentSupply;
    }

    function checkPreSaleTarget() external view returns(bool) {
        return preSaleTarget[msg.sender];
    }
}