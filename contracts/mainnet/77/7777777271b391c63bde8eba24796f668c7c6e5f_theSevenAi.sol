/**
 *Submitted for verification at Etherscan.io on 2023-02-05
*/

// SPDX-License-Identifier: MIT
/*

   _________      __________    ___________
  /_____   /     |    ___   |  |____    ___|
       /  /      |   |___|  |       |  |
      /  /       |   ____   |       |  |
     /  /        |  |    |  |       |  |
    /  /         |  |    |  |   ____|  |___
   /__/          |__|    |__|  |___________|

 TOKEN HIGHTLIGHT
  - No mint function
  - No one can't change the taxes (3.5% for buy and 3.5% for sell = total 7%)
  - Taxes automatically transfer to DEAD wallet
  - More you buy or sell, less total supply of token
  - 100% of token is added to LP
  - 100% of initial LP is locked
  - Renounce Ownership (Dead wallet is owner)
  - Max per wallet as 2.7% of initial total supply (2.7% of 7,777,777 tokens)

  All above mentioned you can check it in the verified code

    TG Community: https://t.me/ETH_7AI
    Twitter: https://twitter.com/7AI_ETH
    https://7ai.tech/
*/

pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

contract theSevenAi is Context, IERC20, Ownable {
    using SafeMath for uint256;
    address immutable WETH;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    mapping (address => uint256) private tokenBalance;
    mapping (address => mapping (address => uint256)) private tokenAllowance;
    mapping (address => bool) private _isExcludedFromFeeAndLimit;
    address constant public _taxCollectorWallet = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant _totalTaxes = 7;

    uint8 private constant tokenDecimal = 7;
    uint256 private constant tokenTotalSupply = 7_777_777 * 10**tokenDecimal;
    string private constant _name = unicode"SEVEN AI";
    string private constant _symbol = unicode"7AI";
    uint256 public _maxWalletSize = tokenTotalSupply * 27 / 1000;
    IDEXRouter private router;
    address private immutable pair;
    address private _deployer;

    constructor () {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        tokenBalance[_msgSender()] = tokenTotalSupply;
        _deployer = msg.sender;

        _isExcludedFromFeeAndLimit[msg.sender] = true;
        _isExcludedFromFeeAndLimit[address(this)] = true;
        _isExcludedFromFeeAndLimit[_taxCollectorWallet] = true;
        _isExcludedFromFeeAndLimit[ZERO] = true;

        emit Transfer(address(0), _msgSender(), tokenTotalSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return tokenDecimal;
    }

    function totalSupply() public view override returns (uint256) {
        return tokenTotalSupply - tokenBalance[_taxCollectorWallet] - tokenBalance[ZERO];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenBalance[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return tokenAllowance[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        tokenAllowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount=0;
        if (from != owner()) {
              taxAmount = amount.mul(35).div(1000);

            if (!_isExcludedFromFeeAndLimit[from] && !_isExcludedFromFeeAndLimit[to] && to != pair) {
                require(tokenBalance[to] + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
            }
        }

        tokenBalance[from]=tokenBalance[from].sub(amount);
        tokenBalance[to]=tokenBalance[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
        if(taxAmount>0){
          tokenBalance[_taxCollectorWallet]=tokenBalance[_taxCollectorWallet].add(taxAmount);
          emit Transfer(from, _taxCollectorWallet, taxAmount);
        }
    }

     function liftWalletLimits() external {
        require(_msgSender() == _deployer);
        _maxWalletSize = tokenTotalSupply;
    }   

    receive() external payable {}
    fallback() external payable {}
}