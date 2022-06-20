// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721URIStorage.sol";
  
contract HyundaiMetamobility is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 internal TOTAL_TOKEN_MAX = 5000;
    uint256 public remainSupply = 5000;
    uint256 public RESERVE = 192;
    uint256 public currentSupply;
    string internal baseURI;

    constructor(string memory baseURI_) ERC721("Hyundai Metamobility", "HMM") {
        baseURI = baseURI_;
    }

    function multiAirDrop(address[] calldata _accounts, uint256[] calldata _amounts) external onlyOwner {
        require(_accounts.length == _amounts.length, "Accounts length must equal amount length");
        for (uint256 i; i < _amounts.length; i++) {
            for (uint256 j; j < _amounts[i]; j++) {
                require(currentSupply < TOTAL_TOKEN_MAX, "TOTAL_TOKEN_MAX EXCESS, Can no longer airdrop.");
                _safeMint(_accounts[i], currentSupply + 1);
                currentSupply++;
                remainSupply--;
            }
        }
    }
    
    function singleAmountAirDrop(address[] memory _accounts, uint256 _amount) external onlyOwner {
        for (uint i = 0; i < _accounts.length; i++) {
            for(uint j = 0; j < _amount; j++) {
                require(currentSupply < TOTAL_TOKEN_MAX, "TOTAL_TOKEN_MAX EXCESS, Can no longer airdrop.");
                _safeMint(_accounts[i], currentSupply+1);
                currentSupply++;
                remainSupply--;
            }
        }
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_; 
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}