// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721URIStorage.sol";
  
contract test is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 internal TOTAL_TOKEN_MAX = 15;
    uint256 internal HOLDER_AIRDROP_TOKEN_MAX = 10;
    uint256 internal RESERVE_MAX = 5;
    string internal baseURI;
    uint256 public currentSupply;
    uint256 public holderAirDropSupply;
    uint256 public eventAirDropSupply;

    constructor(string memory baseURI_) ERC721("TestToken", "TT") {
        baseURI = baseURI_;
    }

    function holderAirDrop(address[] calldata _accounts, uint256[] calldata _amounts) external onlyOwner {
        require(_accounts.length == _amounts.length, "Accounts length must equal amount length");
        for (uint256 i; i < _amounts.length; i++) {
            for (uint256 j; j < _amounts[i]; j++) {
                require(currentSupply < TOTAL_TOKEN_MAX, "TOTAL_TOKEN_MAX EXCESS, Can no longer airdrop.");
                require(holderAirDropSupply < HOLDER_AIRDROP_TOKEN_MAX, "HOLDER_AIRDROP_TOKEN_MAX EXCESS, Can no longer airdrop.");
                _safeMint(_accounts[i], currentSupply + 1);
                currentSupply++;
                holderAirDropSupply++;
            }
        }
    }

    function eventAirDrop(address[] calldata _accounts, uint256[] calldata _amounts) external onlyOwner {
        require(_accounts.length == _amounts.length, "Accounts length must equal amount length");
        for (uint256 i; i < _amounts.length; i++) {
            for (uint256 j; j < _amounts[i]; j++) {
                require(currentSupply < TOTAL_TOKEN_MAX, "TOTAL_TOKEN_MAX EXCESS, Can no longer airdrop.");
                require(eventAirDropSupply < RESERVE_MAX, "RESERVE_MAX EXCESS, Can no longer airdrop.");
                _safeMint(_accounts[i], currentSupply + 1);
                currentSupply++;
                eventAirDropSupply++;
            }
        }
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function multiWithdraw(address[] memory _accounts, uint256[] memory _amounts) external onlyOwner {
        for (uint i = 0; i < _accounts.length; i++) {
            require(payable(_accounts[i]).send(_amounts[i]));
        }
    }
}