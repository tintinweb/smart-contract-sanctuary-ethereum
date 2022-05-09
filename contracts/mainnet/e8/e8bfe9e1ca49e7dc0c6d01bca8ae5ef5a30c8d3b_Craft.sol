// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract Craft is ERC721, Ownable {
    using SafeMath for uint256;

    string public baseURI;
    bool public setBaseUriKey = true;
    uint256 public tokenPrice = 150000000000000000 wei; // 0.15 Ether
    uint256 public remainingPreToken;
    uint256 public TOTAL_TOKEN = 10000;
    uint256 public GENERAL_TOKEN_MAX = 6500;
    uint256 public PRE_TOKEN_MAX = 3000;
    uint256 public reserve = 500;
    uint256 public currentSupply;
    uint256 public generalSupply;
    uint256 public preSupply;
    uint256 public airDropSupply;
    uint256 public generalMintMax = 1;
    uint256 public preMintMax = 1;
    uint256 public generalSaleStartTimestamp;
    uint256 public preSaleStartTimestamp;
    bool public generalSaleActive = true;
    bool public preSaleActive = true;
    uint256 public generalSaleTargetCount;
    uint256 public preSaleTargetCount;
    mapping(address => uint256) public generalMintCount;
    mapping(address => uint256) public preMintCount;
    mapping(address => bool) public generalSaleTarget;
    mapping(address => bool) public preSaleTarget;

    constructor(string memory baseURI_, uint256 _preSaleStartTimestamp, uint256 _generalSaleStartTimestamp) ERC721("Hyundai Metamobility", "HMM") {
        baseURI = baseURI_;
        preSaleStartTimestamp = _preSaleStartTimestamp;
        generalSaleStartTimestamp = _generalSaleStartTimestamp;
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
    
    function airDrop(address[] memory _accounts, uint256 _amount) external onlyOwner {
        require(getAirDropSupply().add((_accounts.length * _amount)) <= reserve + remainingPreToken, "Can no longer airdrop.");
        require(totalSupply().add(_accounts.length * _amount) <= TOTAL_TOKEN, "Can no longer airdrop.");

        for (uint i = 0; i < _accounts.length; i++) {
            for(uint j = 0; j < _amount; j++) {
                _safeMint(_accounts[i], currentSupply+1);
                currentSupply++;
                airDropSupply++;
            }
        }
    }

    function generalMint() external payable {
        require(currentSupply < TOTAL_TOKEN, "sold out.");
        require(block.timestamp >= generalSaleStartTimestamp, "Sale has not started");
        require(generalSaleActive, "Not for General-sale yet.");
        require(generalSupply < GENERAL_TOKEN_MAX, "General-sale sold out.");
        require(generalSaleTarget[msg.sender], "It is not a General-sale target.");
        require(generalMintCount[msg.sender] < generalMintMax, "It is no longer available for purchase.");
        require(msg.value == tokenPrice, "You entered an incorrect amount.");
        _safeMint(msg.sender, currentSupply + 1);
        currentSupply++;
        generalSupply++;
        generalMintCount[msg.sender]++;
    }

    function preMint() external payable {
        require(currentSupply < TOTAL_TOKEN, "sold out.");
        require(block.timestamp >= preSaleStartTimestamp, "Sale has not started");
        require(preSaleActive, "Not for pre-sale yet.");
        require(preSupply < PRE_TOKEN_MAX, "Pre-sale sold out.");
        require(preSaleTarget[msg.sender], "It is not a pre-sale target.");
        require(preMintCount[msg.sender] < preMintMax, "It is no longer available for purchase.");
        require(msg.value == tokenPrice, "You entered an incorrect amount.");
        _safeMint(msg.sender, currentSupply + 1);
        currentSupply++;
        preSupply++;
        preMintCount[msg.sender]++;
    }

    function setGeneralSaleStartTimestamp(uint256 _generalSaleStartTimestamp) external onlyOwner {
        generalSaleStartTimestamp = _generalSaleStartTimestamp;
    }

    function setPreSaleStartTimestamp(uint256 _preSaleStartTimestamp) external onlyOwner {
        preSaleStartTimestamp = _preSaleStartTimestamp;
    }

    function flipGeneralSaleState() external onlyOwner {
        generalSaleActive = !generalSaleActive;
    }

    function flipPreSaleState() external onlyOwner {
        preSaleActive = !preSaleActive;
    }

    function setGeneralMintMax(uint256 _generalMintMax) external onlyOwner {
        generalMintMax = _generalMintMax;
    }

    function setPreMintMax(uint256 _preMintMax) external onlyOwner {
        preMintMax = _preMintMax;
    }

    function setGeneralSaleTarget(address[] memory _account) external onlyOwner {
        for (uint256 i = 0; i < _account.length; i++) {
            if (generalSaleTarget[_account[i]] == false) {
                generalSaleTarget[_account[i]] = true;
                generalSaleTargetCount++;
            }
        }
    }

    function setPreSaleTarget(address[] memory _account) external onlyOwner {
        for (uint256 i = 0; i < _account.length; i++) {
            if (preSaleTarget[_account[i]] == false) {
                preSaleTarget[_account[i]] = true;
                preSaleTargetCount++;
            }   
        }
    }

    function deleteGeneralSaleTarget(address[] memory _account) external onlyOwner {
        for (uint256 i = 0; i < _account.length; i++) {
            if (generalSaleTarget[_account[i]] == true) {
                generalSaleTarget[_account[i]] = false;
                generalSaleTargetCount--;
            }
        }
    }

    function deletePreSaleTarget(address[] memory _account) external onlyOwner {
        for (uint256 i = 0; i < _account.length; i++) {
            if (preSaleTarget[_account[i]] == true) {
                preSaleTarget[_account[i]] = false;
                preSaleTargetCount--;
            }
        }
    }

    function setRemainingPreToken() external onlyOwner {
        preSaleActive = false;
        remainingPreToken = PRE_TOKEN_MAX - preSupply;
    }

    function setTokenPrice(uint256 _tokenPrice) external onlyOwner() {
        tokenPrice = _tokenPrice;
    }

    function totalSupply() internal view returns (uint256) {
        return currentSupply;
    }

    function getAirDropSupply() internal view returns (uint256) {
        return airDropSupply;
    }

    function multiWithdraw(address[] memory _accounts, uint256[] memory _amounts) external onlyOwner {
        for (uint i = 0; i < _accounts.length; i++) {
            require(payable(_accounts[i]).send(_amounts[i]));
        }
    }

    function withdraw(address _account, uint256 _amount) external onlyOwner {
        require(payable(_account).send(_amount));
    }
}