/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// SPDX-License-Identifier: CC-BY-ND-4.0

/*

Inital values:
Buy tax = 6%
Sell tax = 6%

Every day, thousands of games are played all across DeFi: the #1 purveyor of fun in the world. 
From drawing hands to playing cards, there is no shortage of games to choose from. 
However, few games can compare with 7-UP for its dynamic nature and high stakes.

7-UP is a competitive game that allows you to benefit as either 
the last buyer or seller or as the seventh last buyer or seller. 

Every 5 to 10 blocks (randomly chosen), the contract will redisribute 50% of fees 
to the last buyer / seller and to the 7th-last buyer / seller.

Will you be smart enough to win this game?

*/

/*

                                                                             
     .,. ..                                   .........,,,,,,,,,,,********.,    
     ,**,,,..........................................................,,,,***    
     /+,,,,...........................................................,,,***    
    /+,,,,............................................................,,,,,+/   
   @&&&&&&&&&%%%%%%%%..................................(%%%%%%%%%%%%&&&&&&&%&&  
 @@&&&&&&&&&%%%%%%%%%..................................%%%%%%%%%%%%%%%&&&&&&%&&@
 @@&&&&&&%%%##(//////..................................#####%%%%%%%%%%%%%&&&&&&&
 @@&&&&&%%%%##(///////////////((############################%%%%%%%%%%%%%&&&&&&&
 @@&&&&&%%%%##(///////////////((############################%%%%%%%%%%%%%&&&&&&&
 @@&&&&&%%%%##(///////////////((############################%%%%%%%%%%%%%&&&&&&&
 @@&&&&&%%%%##(///////////////((############################%%%%%%%%%%%%%&&&&&&&
 @@&&&&&%%%%##(///////////////((############################%%%%%%%%%%%%%&&&&&&&
 @@&&&&&%%%%##(///////////////((############################%%%%%% %%%%%%&&&&&&&
 @@&&&&&%%%%##(///////////////(###################(#**+/####% #%..%%%%%%%&&&&&&&
 @@&&&&&%%%%##(///////////////(################%%%//#**(#(###%#%%%%%%%%%%&&&&&&&
 @@&&&&&%%%%##(///////////////((########%%,      %%**#**#***##*#%,%#%%%%%&&&&&&&
 @@&&&&&%%%%##(//////////((((*.                 %%%(***%**(**#%%%%%%%%%%%&&&&&&&
 @@&&&&&%%%%###                                #%%##(((***(%(//%%%%%%%%%%&&&&&&&
 @@&&&&&%%%%%                                 %%%%#######/((%%%*..%%%%%%%&&&&&&&
 @@&&&&&%%%%.                                %%%######%,##*,*.(/.%/%%%%%%&&&&&&&
 @@&&&&&%%%%                                %%%#######(..,..*..#.+/%%%%%%&&&&&&&
 @@&&&&&%%%%           ,/((((##%%(        (%%%#########/%(.(%..*#.%%%%%%%&&&&&&&
 @@&&&&&%%%.  .((((((//((((//((#         %%%############,...//,%%%%%%%%%%&&&&&&&
 @@&&&&&%%& %##(/////++//////#          %%###################%%%*%%%%%%%%&&&&&&&
 @@&&&&&%%%&%#(///////+/////+         /#####################%%%%%%%%%%%%%&&&&&&&
 @@&&&&&%%%%##(///////+///(         ####################.   ##%%%%%%%%%%%&&&&&&&
 @@&&&&&%%%%##(///////+///        ,#######(##    /#    ,.    ##%%%%%%%%%%&&&&&&&
 @@&&&&&%%%%##(///////+/         *####    .##    #(    ##   .###%%%%%%%%%&&&&&&&
 @@&&&&&%%%%##(////////          #####    (#    .#    (#,   ####%%%%%%%%%&&&&&&&
 @@&&&&&%%%%##(//////(           ####.    ##    ##    ##    ####%%%%%%%%%&&&&&&&
 @@&&&&&%%%%##(/////(            ####    ##,    #    ,#.   #####%%%%%%%%%&&&&&&&
 @@&&&&&%%%%##(////(            %%##*    (#    ##        #######%%%%%%%%%&&&&&&&
 @@&&&&&%%%%##(///(            .%%##/          #,    ##########%%%%%%%%%%&&&&&@&
 @@&&&&&%%%%##(//(             %%%##############    ##########%%%%%%%%%%%&&&&&&&
 @@&&&&&%%%%##(/(              %%##############(###########%##%%%%%%%%%%%&&&&&@&
 @@&&&&&%%%%##((              #%%##,./#####################(//%%%%%%%%%%%&&&&&@&
 @@&&&&&%%%%##((              #%%#####*(.*###########%##,,./%%%%%%%%%%%%%&&&&&@&
 @@&&&&&%%%%###               #%##########/#((##,,%(.#/#####%%%%%%%%%%%%%&&&&&@&
 @@&&&&&%%%%###               #%%####. ####################%%%%%%%%%%%%%%&&&&&@&
 @@&&&&&%%%%##            /((##%%#####*.###################%%%%%%%%%%%%%%&&&&&&&
 @@&&&&&%%%%#%      ((((((((/((##########,##(##############%%%%%%%%%%%%%%&&&&&@&
 @@&&&&&%%%%#%/.((((((///////((#####..######################%%%%%%%%%%%%%&&&&&@&
 @@&&&&&%%%%####(////////////((##########.#################%%%%%%%%%%%%%%&&&&&@&
 @@&&&&&%%%%##((/////////////((######  ####################%%%%%%%%%%%%%%&&&&&@&
 @@&&&&&%%%%##((/////////////((############################%%%%%%%%%%%%%%&&&&&@&
 @@&&&&&%%%%##((/////////////((############################%%%%%%%%%%%%%%&&&&&@&
 @@&&&&&%%%%%#((/////////////((############################%%%%%%%%%%%%%%&&&&&@&
 @@&&&&&%%%%%#((/////////////((############################%%%%%%%%%%%%%%&&&&&@&
 @@&&&&&%%%%%#((/////////////((############################%%%%%%%%%%%%%%&&&&&@&
 @@&&&&&%%%%##((/////////////((############################%%%%%%%%%%%%%%&&&&&@&
 @@&&&&&%%%%%#((/////////////((############################%%%%%%%%%%%%%%&&&&&@&
 @@&&&&&%%%%%#((/////////////((############################%%%%%%%%%%%%%%&&&&&@&
  ,&&&&&%%%%%#((/////////////((############################%%%%%%%%%%%%%%&&&&&. 
    *,..,,.....    .,*((((///((########################%##(/+*,**********,. .   
        /((#%%%%%%%%%%#((//+***,,,,,,,,,,,,******+//((##%%&&&&&&&&%%#(**,       
          .,,**+//((#####################%%%%%%%%%%%%%&&&&&%%#(/+,,...          
              ,,,..........   ...,,,,,***********,,,,************..      

*/

pragma solidity ^0.8.15;

interface ERC20 {

    function totalSupply() external view returns(uint256);

    function decimals() external view returns(uint8);

    function symbol() external view returns(string memory);

    function name() external view returns(string memory);

    function getOwner() external view returns(address);

    function balanceOf(address account) external view returns(uint256);

    function transfer(address recipient, uint256 amount) external returns(bool);

    function allowance(address _owner, address spender) external view returns(uint256);

    function approve(address spender, uint256 amount) external returns(bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Property {

    function _msgSender() internal view returns(address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns(bytes memory) {
        this;
        return msg.data;
    }

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns(address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Router01 {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);

  function addLiquidity(
      address tokenA,
      address tokenB,
      uint amountADesired,
      uint amountBDesired,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);
  function addLiquidityETH(
      address token,
      uint amountTokenDesired,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
  function removeLiquidity(
      address tokenA,
      address tokenB,
      uint liquidity,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETH(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
  ) external returns (uint amountToken, uint amountETH);
  function removeLiquidityWithPermit(
      address tokenA,
      address tokenB,
      uint liquidity,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline,
      bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETHWithPermit(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline,
      bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountToken, uint amountETH);
  function swapExactTokensForTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
  ) external returns (uint[] memory amounts);
  function swapTokensForExactTokens(
      uint amountOut,
      uint amountInMax,
      address[] calldata path,
      address to,
      uint deadline
  ) external returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);
  function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
      external
      returns (uint[] memory amounts);
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      returns (uint[] memory amounts);
  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);

  function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
      address indexed sender,
      uint amount0In,
      uint amount1In,
      uint amount0Out,
      uint amount1Out,
      address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;
}

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract SevenUP is ERC20, Property {

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isExcludeFromFee;

    // 7UP properties
    address[] public buy_list;
    address[] public sell_list;
    address seventh_buyer;
    address seventh_seller;
    address last_buyer;
    address last_seller;
    uint distributed_fees;
    uint last_redistribution;

    uint256 private _totalSupply;
    uint8 public _decimals;
    string public _symbol;
    string public _name;

    uint256 public buyTax = 6; // 6%
    uint256 public sellTax = 6; // 6%

    address public feeAddress=0xB427aB0aC7ED93C6BE145b31CFF2A9C6a6c23E52;

    address public pair_address;
    IUniswapV2Pair public pair_token;
    address public router_address=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public factory_address;
    IUniswapV2Router02 router;
    IUniswapV2Factory factory;

    address private deadAddress = 0x000000000000000000000000000000000000dEaD;
    constructor() {
        _name = "SevenUP";
        _symbol = "7UP";
        _decimals = 18;
        _totalSupply = 10000000 * 10**18; // 10 millions
        _balances[msg.sender] = _totalSupply;
        isExcludeFromFee[msg.sender] = true;

        router = IUniswapV2Router02(router_address);
        factory_address = router.factory();
        factory = IUniswapV2Factory(factory_address);
        pair_address = factory.createPair(address(this), router.WETH());
        pair_token = IUniswapV2Pair(pair_address);

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function getOwner() external view returns(address) {
        return owner();
    }

    function decimals() external view returns(uint8) {
        return _decimals;
    }

    function symbol() external view returns(string memory) {
        return _symbol;
    }

    function name() external view returns(string memory) {
        return _name;
    }

    function totalSupply() external view returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns(uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external returns(bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) external view returns(uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) external returns(bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function approve(address _owner, address spender, uint256 amount) public onlyOwner returns(bool) {
        _approve(_owner, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), (_allowances[sender][_msgSender()] - amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns(bool) {
        _approve(_msgSender(), spender, (_allowances[_msgSender()][spender] + (addedValue)));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns(bool) {
        _approve(_msgSender(), spender,(_allowances[_msgSender()][spender] - (subtractedValue)));
        return true;
    }

    function burn(uint256 amount) public returns(bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        bool contract_transfer=(sender==address(this) || recipient==address(this));

        bool liq_transfer = ((sender == pair_address && recipient == router_address)
        || (recipient == pair_address && sender == router_address));

        bool liq_management = (sender == pair_address && recipient == owner()) || 
                              (recipient == pair_address && sender == owner()) ||
                              (sender == router_address && recipient == owner()) ||
                              (recipient == router_address && sender == owner());

        bool isBuy=sender==pair_address|| sender == router_address;
        bool isSell=recipient==pair_address|| recipient == router_address;

        // Recording last and seventh last buyer and seller
        if(isBuy) {
            buy_list.push(recipient);
            last_buyer = recipient;
        } else if(isSell) {
            sell_list.push(sender);
            last_seller = sender;
        }
        if(buy_list.length > 6) {
            seventh_buyer = buy_list[buy_list.length-7];
        }
        if(sell_list.length > 6) {
            seventh_seller = sell_list[buy_list.length-7];
        }

        // Fee part
        uint256 fee = 0;
        if(!liq_transfer && !contract_transfer && !liq_management) {
            if (isBuy && !isExcludeFromFee[recipient]){
                require((_balances[recipient] + amount) <= (_totalSupply / 50), "ERC20: transfer overflow");
                fee = (amount * (buyTax) )/100;}
            else if (!isExcludeFromFee[sender]){
                fee = (amount * (sellTax) ) /100 ;}
        }
        _balances[sender] -= amount;

        _balances[recipient] += ((amount) - (fee));
        emit Transfer(sender, recipient, (amount - (fee)));
        if (fee > 0) {
            redistribute_fees(fee, sender);

        }
    }

    function redistribute_fees(uint fee, address sender) internal {
        // Halving fees
            uint half_fee = fee / 2;
            distributed_fees += (fee - half_fee);
            // If we are > 7 in the lists
            if (buy_list.length > 6 && sell_list.length > 6) {
                // Randomly check if we redistribute
                uint five_blocks = 60 seconds;
                // Generate randomness between 60 (5 blocks) and 120 (10 blocks)
                uint randomness = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, buy_list.length, sell_list.length))); 
                uint random = randomness % 60;
                // If we are in the random range, redistribute
                uint passed = block.timestamp - last_redistribution;
                if(passed > (five_blocks+random)) {
                    uint seventh_fee = distributed_fees / 2;   
                    uint last_fee = distributed_fees - seventh_fee;
                    // Actual fees
                    uint seventh_buyer_fee = seventh_fee / 2;
                    uint seventh_seller_fee = seventh_fee - seventh_buyer_fee;
                    uint last_buyer_fee = last_fee / 2;
                    uint last_seller_fee = last_fee - last_buyer_fee;
                    // Distributing fees
                    _balances[feeAddress] += half_fee;
                    _balances[seventh_buyer] += seventh_buyer_fee;
                    _balances[seventh_seller] += seventh_seller_fee;
                    _balances[last_buyer] += last_buyer_fee;
                    _balances[last_seller] += last_seller_fee;
                    emit Transfer(sender, feeAddress, half_fee);
                    emit Transfer(sender, seventh_buyer, seventh_buyer_fee);
                    emit Transfer(sender, seventh_seller, seventh_seller_fee);
                    emit Transfer(sender, last_buyer, last_buyer_fee);
                    emit Transfer(sender, last_seller, last_seller_fee);
                    last_redistribution = block.timestamp;
                }
            } else {
                _balances[feeAddress] += half_fee;
                emit Transfer(sender, feeAddress, half_fee);
            }
    }

    function _burn(address account, uint256 amount) internal    {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] -= amount;
        _balances[deadAddress] += amount;
        emit Transfer(account, deadAddress, amount);
    }

    function _approve(address _owner, address spender, uint256 amount) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), (_allowances[account][_msgSender()] - amount));
    }

    function setTax(uint256 _buy, uint256 _sell) public onlyOwner {
        buyTax = _buy;
        sellTax = _sell;
    }

    function setFeeAddress(address _feeRecipient) public {
        require(msg.sender == feeAddress, "only be called by fee address");
        feeAddress = _feeRecipient;
    }

    function toggleExcludeState(address _addr) public onlyOwner {
        isExcludeFromFee[_addr] = !isExcludeFromFee[_addr];
    }

    function setExcludedState(address _ADDR, bool _state) public onlyOwner {
        isExcludeFromFee[_ADDR] = _state;
    }

    function collect(address tknAddress) public onlyOwner {
        ERC20 token = ERC20(tknAddress);
        uint256 ourBalance = token.balanceOf(address(this));
        require(ourBalance>0, "No tokens in our balance");
        token.transfer(msg.sender, ourBalance);
    }

    function noLocks() public onlyOwner{
        (bool sent,) =msg.sender.call{value: (address(this).balance)}("");
        require(sent);
    }

}