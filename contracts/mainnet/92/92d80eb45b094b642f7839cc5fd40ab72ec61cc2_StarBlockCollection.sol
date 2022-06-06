// SPDX-License-Identifier: MIT
// StarBlock NFT Marketplace Contracts, https://www.starblock.io/

//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract StarBlockCollection is ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    string private baseTokenURI;

    /* Proxy registry address. */
    ProxyRegistry public proxyRegistry;
    
    IERC20 public tokenAddress;
    uint256 public mintTokenAmount;

    constructor(
      string memory _name, 
      string memory _symbol,
      string memory _baseTokenURI,
      ProxyRegistry _proxyRegistry
    ) ERC721(_name, _symbol) {
      baseTokenURI = _baseTokenURI;
      proxyRegistry = _proxyRegistry;
    }

    // PROXY HELPER METHODS
    function _isProxyForUser(address _user, address _address) internal view returns (bool) {
      return address(_proxy(_user)) == _address;
    }

    function _proxy(address _address) internal view returns (OwnableDelegateProxy) {
      return proxyRegistry.proxies(_address);
    }

    function _baseURI() internal view override returns (string memory) {
      return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
      baseTokenURI = _baseTokenURI;
    }

    function setProxyRegistry(ProxyRegistry _proxyRegistry) external onlyOwner {
      proxyRegistry = _proxyRegistry;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
      (payable(msg.sender)).transfer(address(this).balance);
    }

    function publicMint(
      address _from,
      address _to,
      uint256[] memory _tokenIds
    ) external nonReentrant {
      require(
        _isProxyForUser(_from, _msgSender()), "StarBlockCollection#publicMint: caller is not approved"
      );
      require(_tokenIds.length > 0, "StarBlockCollection#publicMint: tokenIds is empty");
      for (uint256 i = 0; i < _tokenIds.length; i++) {
        _safeMint(_to, _tokenIds[i]);
      }
      _safeTransferToken(_to, mintTokenAmount * _tokenIds.length);
    }

    function setTokenAddressAndMintTokenAmount(IERC20 _tokenAddress, uint256 _mintTokenAmount) external onlyOwner {
      tokenAddress = _tokenAddress;
      mintTokenAmount = _mintTokenAmount;
    }

    function _safeTransferToken(address _to, uint256 _amount) internal {
      if(address(tokenAddress) != address(0) && _amount > 0){
        uint256 bal = tokenAddress.balanceOf(address(this));
        if(bal > 0) {
            if (_amount > bal) {
              tokenAddress.transfer(_to, bal);
            } else {
              tokenAddress.transfer(_to, _amount);
            }
        }
      }
    }

    function withdrawToken() external onlyOwner nonReentrant {
      uint256 bal = tokenAddress.balanceOf(address(this));
      if(bal > 0) {
          tokenAddress.transfer(msg.sender, bal);
      }
    }
}