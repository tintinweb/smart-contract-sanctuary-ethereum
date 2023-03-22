/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

/*
                                                                                                                                                      
                                                                                                                                                      
                                                                           .``'.                                                                      
                                                                          '```'                                                                       
                                                                          ````.  .'`":;l!!!I:,^`'                                                     
                                                                          .```^`;!!I"`''.....'`^,I;^'                                                 
                                                                           .";!!I^.               .'"I`                                               
                                                                           ^!!!:'  ................  .`;`                                             
                                                                         .:!!I"``...             .......^:.                                           
                                                                         :!!I'```'                  .....`;.                                          
                                                                        "!!!`.```.                    ....';.                                         
                                                                       .!!!!.````                       ...'I.                                        
                                                                       `!!!I````.                         ..`:.                                       
                                                                       ,-??_,^`.                           ..:`.                                      
                                                                    '[rxxrrjft-^                            .`;..                                     
                                                                    Innxxrrjft/(                             .!`..                                    
                                                                    ,:"`''.......                            .::...                                   
                                                                 ........................                     :!...                                   
                                                            ................................                  I!'...                                  
                                                        ................`)txxf|{+;`...........               .!!'...                                  
                                                       `";~]{11['.......'`'.......'`'...........             "!l....                                  
                                                    .^l,^`''''``'................'...............           .!!,....                                  
                                                    .'.......................^";;;;;;;'..^.......           :!!`...                                   
                                                 .  .,;,"""^^^'.............^I_<!",+>,!,"`.......          '!!,...                                    
                                 `,"l-,^         .""]"...";!!:"`...........^<`^,"``;!I;...........         I!I'..                                     
                               '^\ti^. ^^          .'..`~iI"`;i>'......... +>``''''`:^_'..'........       ^!l'.                                       
                               Iffj;  <j'         ..'..,`,^`'^:,l..........:_`'''''`",>...`........      .!:'.                                        
                                :jrrxfxx.         ....':`'''.'""!...........">!lI;,``'....'.........     I"..                                         
                                 .;tnnnn^         ...'.,`````^",,.............`,".........'.........    "'...                                         
                                  ..'",,.        ....'.......'"^..........................'........    '' ...                                         
                                 .......         .........................................'........    "   ..                                         
                                .......           ...'..........................`^........'.......    "`    ..                                        
                              .'.......           ...'...........'`,_,`'..'`">/}'................     !'     ..                                       
                             .'.......              ..'.............:xczzzn~I:`...............       .!'      .....                                   
                            .'........               .................^;i!`'...............          .!"       ......                                 
                           .'.........                  ..............................`^              !!.       .....'.                               
                          .'..........                      .....................'^l[//.              "!,         .'''.                               
                          '..........                              .........'^:+|jfttt+               .l!^                                            
                         .'..........                                   |<|xxrrrjjfttt,                '!!^                                           
                         '...........                                  .n`lxxrrrjjfttt^                 `^'..                                         
                        .'..........                                   `u.lxxrrrjjfttt"                 ......                                        
                        '...........                                   ,j"}xxrrrjjf/-,.        '`.       ....'.                                       
                       .'...........                                 .;nnnnxxrrf?;`.........'l\ftfi.      .'.''                                       
                       ............                       ',~i.......^unnnt[!"'............;jrjjxxrf`      ....                      ..               
                       ............                  .'^;|rj;.........'`'................')xrrrnnxxrf.                        '!_][-?l' .<            
                       ............         .'`,;~}/jrrrrx)`.......    ..........'......'fxxrrnnnxrrj,                        1nnxj^   :},            
                       ............`^,;i_{/fjjjjrrrrxxt?{:.......         ....',,`......1nxxrxunnxrrj^                      ...`>trr{+>t\             
                       ...........<ffffjjjjrrrr/}<:^'.  ........         ',><;!~>;'...."unxxrrunnxrr|                      .......':}ft"`             
                         .........\jjf(}+!:^`.        ..........       ."I~I>{}[I'.....[nnxxrrrrrxxr/                    ........    .'               
                             ...  ..                ............      .^",^."lI;.......tnnxxrrjftxxrj'                 ........'                      
                                                   ...............    ',,,,"",,,'....../nnxxrrjf[\xrj,                ........'.                      
                                                   ....................,l!,"""`........~nnxxrrj] -xrj]              .........'.                       
                                                   ....................................'xnxxrr+. ;xrjf.           ..........'.                        
                                                    ...................................."jxx{^.  `rrjj,         ...........'.                         
                                                     ........''''.........................`'..    rrjj)        ...........'.                          
                                                        ......'...............................    ?rjjf'     ............'.                           
                                                         .....'..............................     ^rjjf!   .............'.                            
                                                         .....'.............................       tjjf/...............'.                             
                                                         ...............................'..        :jj1^.............'.                               
                                                          .............................'..          {,................                                
                                                           .......................''....            ................                                  
                                                            .........'.'''''''''''....              ..............                                    
                                                               .................                      ..........                                      
                                                                                                                                                      

*/
// Siri Natural Language Generation   
// TG: https://t.me/SiriNaturalLanguageGeneration
// TWITTER: https://twitter.com/snlg_official?s=21&t=XFajMrULyEDwRmiuCZx3Yg
// WEBSITE: https://www.SiriNLG.com
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract Ownable is Context {
    address private _owner;
    address private asdasd;
    uint256 private _lockTime;

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
    
    function waiveOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

}
interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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
// File: SNLG.sol

/*
                                                                                                                                                      
                                                                                                                                                      
                                                                           .``'.                                                                      
                                                                          '```'                                                                       
                                                                          ````.  .'`":;l!!!I:,^`'                                                     
                                                                          .```^`;!!I"`''.....'`^,I;^'                                                 
                                                                           .";!!I^.               .'"I`                                               
                                                                           ^!!!:'  ................  .`;`                                             
                                                                         .:!!I"``...             .......^:.                                           
                                                                         :!!I'```'                  .....`;.                                          
                                                                        "!!!`.```.                    ....';.                                         
                                                                       .!!!!.````                       ...'I.                                        
                                                                       `!!!I````.                         ..`:.                                       
                                                                       ,-??_,^`.                           ..:`.                                      
                                                                    '[rxxrrjft-^                            .`;..                                     
                                                                    Innxxrrjft/(                             .!`..                                    
                                                                    ,:"`''.......                            .::...                                   
                                                                 ........................                     :!...                                   
                                                            ................................                  I!'...                                  
                                                        ................`)txxf|{+;`...........               .!!'...                                  
                                                       `";~]{11['.......'`'.......'`'...........             "!l....                                  
                                                    .^l,^`''''``'................'...............           .!!,....                                  
                                                    .'.......................^";;;;;;;'..^.......           :!!`...                                   
                                                 .  .,;,"""^^^'.............^I_<!",+>,!,"`.......          '!!,...                                    
                                 `,"l-,^         .""]"...";!!:"`...........^<`^,"``;!I;...........         I!I'..                                     
                               '^\ti^. ^^          .'..`~iI"`;i>'......... +>``''''`:^_'..'........       ^!l'.                                       
                               Iffj;  <j'         ..'..,`,^`'^:,l..........:_`'''''`",>...`........      .!:'.                                        
                                :jrrxfxx.         ....':`'''.'""!...........">!lI;,``'....'.........     I"..                                         
                                 .;tnnnn^         ...'.,`````^",,.............`,".........'.........    "'...                                         
                                  ..'",,.        ....'.......'"^..........................'........    '' ...                                         
                                 .......         .........................................'........    "   ..                                         
                                .......           ...'..........................`^........'.......    "`    ..                                        
                              .'.......           ...'...........'`,_,`'..'`">/}'................     !'     ..                                       
                             .'.......              ..'.............:xczzzn~I:`...............       .!'      .....                                   
                            .'........               .................^;i!`'...............          .!"       ......                                 
                           .'.........                  ..............................`^              !!.       .....'.                               
                          .'..........                      .....................'^l[//.              "!,         .'''.                               
                          '..........                              .........'^:+|jfttt+               .l!^                                            
                         .'..........                                   |<|xxrrrjjfttt,                '!!^                                           
                         '...........                                  .n`lxxrrrjjfttt^                 `^'..                                         
                        .'..........                                   `u.lxxrrrjjfttt"                 ......                                        
                        '...........                                   ,j"}xxrrrjjf/-,.        '`.       ....'.                                       
                       .'...........                                 .;nnnnxxrrf?;`.........'l\ftfi.      .'.''                                       
                       ............                       ',~i.......^unnnt[!"'............;jrjjxxrf`      ....                      ..               
                       ............                  .'^;|rj;.........'`'................')xrrrnnxxrf.                        '!_][-?l' .<            
                       ............         .'`,;~}/jrrrrx)`.......    ..........'......'fxxrrnnnxrrj,                        1nnxj^   :},            
                       ............`^,;i_{/fjjjjrrrrxxt?{:.......         ....',,`......1nxxrxunnxrrj^                      ...`>trr{+>t\             
                       ...........<ffffjjjjrrrr/}<:^'.  ........         ',><;!~>;'...."unxxrrunnxrr|                      .......':}ft"`             
                         .........\jjf(}+!:^`.        ..........       ."I~I>{}[I'.....[nnxxrrrrrxxr/                    ........    .'               
                             ...  ..                ............      .^",^."lI;.......tnnxxrrjftxxrj'                 ........'                      
                                                   ...............    ',,,,"",,,'....../nnxxrrjf[\xrj,                ........'.                      
                                                   ....................,l!,"""`........~nnxxrrj] -xrj]              .........'.                       
                                                   ....................................'xnxxrr+. ;xrjf.           ..........'.                        
                                                    ...................................."jxx{^.  `rrjj,         ...........'.                         
                                                     ........''''.........................`'..    rrjj)        ...........'.                          
                                                        ......'...............................    ?rjjf'     ............'.                           
                                                         .....'..............................     ^rjjf!   .............'.                            
                                                         .....'.............................       tjjf/...............'.                             
                                                         ...............................'..        :jj1^.............'.                               
                                                          .............................'..          {,................                                
                                                           .......................''....            ................                                  
                                                            .........'.'''''''''''....              ..............                                    
                                                               .................                      ..........                                      
                                                                                                                                                      

*/
// Siri Natural Language Generation   
// TG: https://t.me/SiriNaturalLanguageGeneration
// TWITTER: https://twitter.com/snlg_official?s=21&t=XFajMrULyEDwRmiuCZx3Yg
// WEBSITE: https://www.SiriNLG.com


pragma solidity ^0.8.18;


contract SNLG is Context, IERC20, Ownable {
    
    using SafeMath for uint256;
    using Address for address;
    
    string private _name = "Siri Natural Language Generation";
    string private _symbol = "SNLG";
    uint8 private _decimals = 9;
    uint256 private _totalSupply =  10000000 * 10**_decimals;           
    uint256 private minimumTokensBeforeSwap = 50000 * 10**_decimals;
    uint256 public _walletMax = 200000 * 10**_decimals;
    
    address payable public marketingWalletAddress = payable(0xe327352bF8890A8Ff14d6a6685AF13CE48bb23Cd);
    address payable public teamWalletAddress = payable(0xe327352bF8890A8Ff14d6a6685AF13CE48bb23Cd);
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isMarketPair;
    mapping (address => bool) public isWalletLimitExempt;

    uint256 public _buyLiquidityFee = 0;
    uint256 public _buyMarketingFee = 25;
    uint256 public _buyTeamFee = 0;
    
    uint256 public _sellLiquidityFee = 0;
    uint256 public _sellMarketingFee = 25;
    uint256 public _sellTeamFee = 0;

    uint256 public _liquidityShare = 0;
    uint256 public _marketingShare = 100;
    uint256 public _teamShare = 0;

    uint256 public _totalTaxIfBuying = 25;
    uint256 public _totalTaxIfSelling = 25;
    uint256 public _totalDistributionShares = 100;


    IDEXRouter public idexV2Router;
    address public idexPair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyByLimitOnly = true;
    bool public start=false;
    bool public walletLimitCheck=true;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    event shareToken(uint256 team,uint256 marketing, uint256 supply);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {

        IDEXRouter _idexV2Router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        idexPair = IDEXFactory(_idexV2Router.factory())
            .createPair(address(this), _idexV2Router.WETH());

        idexV2Router = _idexV2Router;
        _allowances[address(this)][address(idexV2Router)] = _totalSupply;

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        
        _totalTaxIfBuying = _buyLiquidityFee.add(_buyMarketingFee).add(_buyTeamFee);
        _totalTaxIfSelling = _sellLiquidityFee.add(_sellMarketingFee).add(_sellTeamFee);
        _totalDistributionShares = _liquidityShare.add(_marketingShare).add(_teamShare);

        isWalletLimitExempt[owner()] = true;
        isWalletLimitExempt[address(idexPair)] = true;
        isWalletLimitExempt[address(this)] = true;

        isMarketPair[address(idexPair)] = true;

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
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

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setMarketPairStatus(address account, bool newValue) public onlyOwner {
        isMarketPair[account] = newValue;
    }

    
    function setIsExcludedFromFee(address account, bool newValue) public onlyOwner {
        isExcludedFromFee[account] = newValue;
    }


    function setBuyTaxes(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newTeamTax) external onlyOwner() {
        _buyLiquidityFee = newLiquidityTax;
        _buyMarketingFee = newMarketingTax;
        _buyTeamFee = newTeamTax;

        _totalTaxIfBuying = _buyLiquidityFee.add(_buyMarketingFee).add(_buyTeamFee);
    }

    function setSellTaxes(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newTeamTax) external onlyOwner() {
        _sellLiquidityFee = newLiquidityTax;
        _sellMarketingFee = newMarketingTax;
        _sellTeamFee = newTeamTax;

        _totalTaxIfSelling = _sellLiquidityFee.add(_sellMarketingFee).add(_sellTeamFee);
    }
    
    function setDistributionSettings(uint256 newLiquidityShare, uint256 newMarketingShare, uint256 newTeamShare) external onlyOwner() {
        require(newLiquidityShare.add(newMarketingShare).add(newTeamShare) <= 100, "Share exceeds the 100%.");
        _liquidityShare = newLiquidityShare;
        _marketingShare = newMarketingShare;
        _teamShare = newTeamShare;

        _totalDistributionShares = _liquidityShare.add(_marketingShare).add(_teamShare);
    }

    function setNumTokensBeforeSwap(uint256 newLimit) external onlyOwner() {
        minimumTokensBeforeSwap = newLimit;
    }

    function setMarketingWalletAddress(address newAddress) external onlyOwner() {
        marketingWalletAddress = payable(newAddress);
    }

    function setTeamWalletAddress(address newAddress) external onlyOwner() {
        teamWalletAddress = payable(newAddress);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }

    function setSwapAndLiquifyByLimitOnly(bool newValue) public onlyOwner {
        swapAndLiquifyByLimitOnly = newValue;
    }

    function setIsWalletLimitExempt(address holder, bool exempt) external onlyOwner {
        isWalletLimitExempt[holder] = exempt;
    }

    function setWalletLimit(uint256 newLimit) external onlyOwner {
        _walletMax  = newLimit;
    }

    function switchWalletCheck(bool value) public onlyOwner{
        walletLimitCheck = value;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(deadAddress));
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    receive() external payable {}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(start,"The market is closed");

        if(inSwapAndLiquify)
        { 
            return _basicTransfer(sender, recipient, amount); 
        }
        else
        {             

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
            if (overMinimumTokenBalance && !inSwapAndLiquify && !isMarketPair[sender] && swapAndLiquifyEnabled) 
            {
                if(swapAndLiquifyByLimitOnly)
                    contractTokenBalance = minimumTokensBeforeSwap;
                swapAndLiquify(contractTokenBalance);    
            }

            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            uint256 finalAmount = (isExcludedFromFee[sender] || isExcludedFromFee[recipient]) ? 
                                         amount : takeFee(sender, recipient, amount);

            if(walletLimitCheck && !isWalletLimitExempt[recipient])
                require(balanceOf(recipient).add(finalAmount) <= _walletMax);                             

            _balances[recipient] = _balances[recipient].add(finalAmount);

            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapAndLiquify(uint256 tAmount) private lockTheSwap {
        
        uint256 tokensForLP = tAmount.mul(_liquidityShare).div(_totalDistributionShares).div(2);
        uint256 tokensForSwap = tAmount.sub(tokensForLP);

        swapTokensForEth(tokensForSwap);
        uint256 amountReceived = address(this).balance;
        uint256 totalBNBFee = _totalDistributionShares.sub(_liquidityShare.div(2));
        
        uint256 amountBNBLiquidity = amountReceived.mul(_liquidityShare).div(totalBNBFee).div(2);
        uint256 amountBNBTeam = amountReceived.mul(_teamShare).div(totalBNBFee);
        uint256 amountBNBMarketing = amountReceived.sub(amountBNBLiquidity).sub(amountBNBTeam);

        emit shareToken(amountBNBTeam,amountBNBMarketing,amountBNBLiquidity);

        if(amountBNBMarketing > 0)
            transferToAddressETH(marketingWalletAddress, amountBNBMarketing);

        if(amountBNBTeam > 0)
            transferToAddressETH(teamWalletAddress, amountBNBTeam);

        if(amountBNBLiquidity > 0 && tokensForLP > 0)
            addLiquidity(tokensForLP, amountBNBLiquidity);
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the idex pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = idexV2Router.WETH();

        _approve(address(this), address(idexV2Router), tokenAmount);

        // make the swap
        idexV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(idexV2Router), tokenAmount);

        // add the liquidity
        idexV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 feeAmount = 0;
        
        if(isMarketPair[sender]) {
            feeAmount = amount.mul(_totalTaxIfBuying).div(100);
        }
        else if(isMarketPair[recipient]) {
            feeAmount = amount.mul(_totalTaxIfSelling).div(100);
        }
        
        if(feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
             emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }

    function setStart(bool newVAlue) external onlyOwner {
        start = newVAlue;
    }

    function recoveryTax() public onlyOwner {
        if(_balances[address(this)]>0)
             _basicTransfer(address(this),msg.sender,_balances[address(this)]);
    }

    
}