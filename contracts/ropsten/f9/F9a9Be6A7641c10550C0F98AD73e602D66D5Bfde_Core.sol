/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract Core is ReentrancyGuard{
  using SafeMath for uint;

  struct NFTStorage{
     uint tokenNo;
     address tokenAddress;
     uint tokenID;
  }

  struct Wallet{
    uint wallet_id;
    address user;
    uint createdAt;
    uint tokenCounter;
    NFTStorage[] tokens;
    //mapping(uint => NFTStorage) numberToToken;
  }

  struct Customer{
      address customerAddress;
      string account_id;
      uint walletId;
  }

  address owner;
  bool paused;

  uint walletId;
  mapping(address => uint) customerToWallet; 
  mapping(address => Customer) customerData;
  mapping(address => bool) isValidCustomer;
  mapping(uint => Wallet) idToWallet;
  mapping(uint => bool) isWalletActive;

  mapping(address => bool) isOwner;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  constructor()  {
      owner = msg.sender;
      walletId = 0;
      paused = false;
  }

  function registerUser(address _customer, string memory _accountId) external onlyOwner {
      require(!isValidCustomer[_customer], "Customer has already been created");
      Customer storage customer = customerData[_customer];
      customer.customerAddress = _customer;
      customer.account_id = _accountId;

      isValidCustomer[_customer] = true;
  }
 
  function createWallet() external returns(uint) {
      require(isValidCustomer[msg.sender], "Customer needs to be registered first");
      require(!isOwner[msg.sender], "Customer has already created a wallet");
      walletId++;

      Wallet storage wl = idToWallet[walletId];
      wl.wallet_id = walletId;
      wl.user = msg.sender;
      wl.createdAt = block.timestamp;
      wl.tokenCounter = 0;
      
      customerToWallet[msg.sender] = walletId;
      isOwner[msg.sender] = true;
      isWalletActive[walletId] = true;
      return walletId;
  }

  function addNFTtoWallet(address _customer, address _tokenAddress, uint _tokenId) external onlyOwner nonReentrant{
      require(isValidCustomer[_customer], "Customer needs to be registered first"); 
      require(isOwner[_customer], "Customer has not created a wallet");
      Wallet storage wl = idToWallet[customerToWallet[_customer]];
      wl.tokenCounter++;
      wl.tokens.push(NFTStorage(wl.tokenCounter, _tokenAddress, _tokenId));
  }

  function getWallet() external view returns(Wallet memory) {
     require(isValidCustomer[msg.sender], "User needs to be registered first"); 
     require(isOwner[msg.sender], "User has not created a wallet");
     require(isWalletActive[customerToWallet[msg.sender]], "User's wallet has been suspended");
     return idToWallet[customerToWallet[msg.sender]];
  }
}