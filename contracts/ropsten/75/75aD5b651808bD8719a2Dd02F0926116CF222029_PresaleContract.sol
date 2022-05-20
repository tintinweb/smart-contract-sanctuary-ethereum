/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

pragma solidity ^0.6.0;

/**
 * @title SafeMath
 * Math operations with safety checks that throw on error
 *
*/
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint a, uint m) internal pure returns (uint r) {
    return (a + m - 1) / m * m;
  }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"Only Owner!");
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
interface ERC20Token {
    function transfer(address to, uint256 tokens) external returns (bool success);
    function burn(uint256 _amount) external;
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
}


contract PresaleContract is Owned {
    
    using SafeMath for uint256;
    bool public isPresaleOpen;
    
    //ERC20 token address and decimals
    address public tokenAddress;
    uint256 public tokenDecimals;
    uint256 public totalSold = 0;
    
    //amount of tokens per ether 100 indicates 1 token per eth
    uint256 public tokenRatePerEth = 16530622111464;
    //decimal for tokenRatePerEth,
    //2 means if you want 100 tokens per eth then set the rate as 100 + number of rateDecimals i.e => 10000
    uint256 public rateDecimals = 0;
    
    //max and min token buy limit per account //in wei
    uint256 public minEthLimit = 50000000000000000;
    uint256 public maxEthLimit = 20000000000000000000;
    
    mapping(address => uint256) public usersInvestments;
    
    address public recipient;
   
    constructor(address _token, address _recipient, uint256 _decimals, uint256 _tokenRate, uint256 _rateDecimals, uint256 _minBuy, uint256 _maxBuy) public {
        tokenAddress = _token;
        recipient = _recipient;
        isPresaleOpen = true;
        tokenDecimals = _decimals;
        tokenRatePerEth = _tokenRate;
        rateDecimals = _rateDecimals;
        minEthLimit = _minBuy;
        maxEthLimit = _maxBuy;
    }
    
    function startPresale() external onlyOwner {
        require(!isPresaleOpen, "Presale is open");
        
        isPresaleOpen = true;
    }
    
    function closePresale() external onlyOwner {
        require(isPresaleOpen, "Presale is not open yet.");
        
        isPresaleOpen = false;
    }
    
    function setTokenAddress(address token) external onlyOwner {
        require(tokenAddress == address(0), "Token address is already set.");
        require(token != address(0), "Token address zero not allowed.");
        
        tokenAddress = token;
    }
    
    function setTokenDecimals(uint256 decimals) external onlyOwner {
       tokenDecimals = decimals;
    }
    
    function setMinEthLimit(uint256 amount) external onlyOwner {
        minEthLimit = amount;    
    }
    
    function setMaxEthLimit(uint256 amount) external onlyOwner {
        maxEthLimit = amount;    
    }
    
    function setTokenRatePerEth(uint256 rate, uint256 decimals) external onlyOwner {
        tokenRatePerEth = rate;
        rateDecimals = decimals;
    }
    
    function setRateDecimals(uint256 decimals) external onlyOwner {
        rateDecimals = decimals;
    }

    function setRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "Address zero not allowed.");
        recipient = _recipient;
    }

    receive() payable external {
        buyToken();
    }


    function buyToken() public payable {
        require(isPresaleOpen, "Presale is not open.");
        require(
                usersInvestments[msg.sender].add(msg.value) <= maxEthLimit
                && usersInvestments[msg.sender].add(msg.value) >= minEthLimit,
                "Installment Invalid."
            );
        
        //calculate the amount of tokens to transfer for the given eth
        uint256 tokenAmount = getTokensPerEth(msg.value);
        
        require(ERC20Token(tokenAddress).transfer(msg.sender, tokenAmount), "Insufficient balance of presale contract!");
        
        usersInvestments[msg.sender] = usersInvestments[msg.sender].add(msg.value);
        
        totalSold = totalSold + msg.value;

        //send received funds to the owner
         payable(recipient).transfer(msg.value);
         
    }
    
    function getTokensPerEth(uint256 amount) internal view returns(uint256) {
        return amount.mul(tokenRatePerEth).div(
            10**(uint256(tokenDecimals).sub(tokenDecimals).add(rateDecimals))
            );
    }
    
    function burnUnsoldTokens() external onlyOwner {
        require(!isPresaleOpen, "You cannot burn tokens until the presale is closed.");
        
        ERC20Token(tokenAddress).burn(ERC20Token(tokenAddress).balanceOf(address(this)));
    }
    
    function getUnsoldTokens() external onlyOwner {
        require(!isPresaleOpen, "You cannot get tokens until the presale is closed.");
        
        ERC20Token(tokenAddress).transfer(owner, ERC20Token(tokenAddress).balanceOf(address(this)) );
    }
}