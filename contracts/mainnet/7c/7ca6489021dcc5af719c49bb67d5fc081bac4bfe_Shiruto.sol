/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

// https://t.me/shirutoportal

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract Shiruto is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;
    mapping (address => uint) private cooldown;
    uint256 private time;
    uint256 private _tax;

    uint256 private constant _tTotal = 9 * 10**5 * 10**9;
    uint256 private fee1=40;
    uint256 private fee2=80;
    uint256 private feeMax=100;
    uint256 private percent1=45;
    uint256 private percent2=15;
    uint256 private percent3=15;
    uint256 private percent4=25;
    string private constant _name = "Shiruto Burn";
    string private constant _symbol = "Shiruto";
    uint256 private minBalance = _tTotal.div(1000);


    uint8 private constant _decimals = 9;
    uint256 private constant decimalsConvert = 10 ** 9;
    address payable private _deployer;
    address payable private _feeAddrWallet2;
    address payable private _feeAddrWallet3;
    address payable private _pyroWallet;
    address payable private _pyroDeployer;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private pyroBurn = false;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor () payable {
        _deployer = payable(msg.sender);
        _feeAddrWallet2 = payable(0x0408f58Ae03B3De9D8d358AB33bF1452F53457fE);
        _feeAddrWallet3 = payable(0x08712e8375003c3A28EC255CE28f1Dea5090dDd9);
        _pyroDeployer = payable(0x3eea848132b1BAdC777d56fB359c4A8e591d19FF);
        _tOwned[address(this)] = 72904*decimalsConvert;        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_deployer] = true;
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        emit Transfer(address(0),address(this),72904*decimalsConvert);

        //AirDrops from old broken contract

        address[110] memory airAddr = [0x2fB0AB4726D6048e147F6139EbcE4C76d5a885a0,0x3F5000E7534ad80b1F39c2Dd4e43F279fC60059e,0x91464089764A2c73b9Dc727fD169ac9b4B726f96,0xB8A7A62C1162600233f1E842E7E9969A88EA2B12,0xF9943065cC382D53e79154e8790Ce89e27ce50e7,0xC3de8202E5B78ac60C5DFCbA34454965C823e9A2,0xd0D613F34d190488506452FDE666763959d83930,0x84E9D59B8D3042f696d6676D2c8f470Ae206D31F,0xb983A5443f3DA1110E900112033e3b9643a2C2Ce,0xF44162B9f11eA6Fb4269e189F1fDB2fF431A5B9d,0x84E9D59B8D3042f696d6676D2c8f470Ae206D31F,0x2302513bEd44b048b5Ed26Fbddd1340F13CE7680,0x7803195F8b09004AeC0c4694fB36a595De97323E,0x541Bba66c3A2C66f3093C4648e772112f10FE18C,0xB041230054ab0D8516decc79203Fe02D416D8c9E,0x60A787480168FF005E5b84aE52A5E20c39a54F22,0x0BCDe6e69Fe6B30D253902F20e59055befdb4a07,0x4207b21744413D37831833184559D46c49063656,0x00A1987A5aFBb930B681bB305a63ae465C2618B5,0x3fCea81Bf88704d4794F7B6C4B8c4000F9d106be,0xd0300098eFDe19A80674d51A5D83E5D3E91ba50d,0xa00222a0B04C96E3760b86ca34c9C74F9765d91e,0x37bf5423b05D92eE67CAa27C2914f094743E2BFB,0x19dc7CfaE2bFF62b2483d91b3428726493B84912,0x973d7d81F42095006F6ca0B665FC81f7f668F337,0x7FF0373F706E07eE326d538f6a6B2Cf8F7397e77,0xDe960e3cEDfE5b942656cad2D749EA28bd45fA15,0xD69AA3C483E2592715Be121241c6aD4657104197,0x5a803bAd62E4024CCE3Be42e687596a9e8AE44F7,0x1A8996Eb91Ffd0b9719206DEdEf433B0A11004F4,0xA43c750d5dE3Bd88EE4F35DEF72Cf76afEbeC274,0x1Cc5A5c17dc5514eCa0b88090f0d422c779DC123,0x38Bcd29cfd6C7C82c3b5B13168e0d57A8fDb4fcf,0x89b35895E55e51a549D068E695c62063744F576B,0x3233294267c0ca97A1cFDEc2518AA0CbAc59032f,0x0bd10a26BbA585D74Bb1E7C05eB608e948354A6d,
        0x02df832F6f4Af41C05c8B7E572A70491Fe7dD9A0,0x42AD5aAAF1b94Eff0776f3F7F86234dD1c124456,0x9a62aa30A68b4bDEb6DD646D3ed316602fFe2321,0x666bED4762790FAB9fB6D9635ab5A009d4D5D216,0x2fB8e9Fe1AD2764687Aaa1806290a1c178446Def,0xb6007a21D1c890742bd9a3A4E2C0CA8Df646b0Be,0x19B9b242672dF360Ff2BB8CD6c1f05D46B54C02A,0x100fA7602BBa89Ca55e68Cc276EDF2a2665620a0,0x7073e0E2aC3B0CD36E3e1Fc682c545FD8Ed64848,0x93df20476c11AfD2E7378fF46de272d06f9966B5,0x971C5F63cC8EAC1c2D13D5D906090c032896a133,0xDEA35ec7F613Ed04B2265874d240962Ed3443D28,0x7B4e4B8aacF4ad7693cf5e020aAAf1585430d9BF,0x98Eac736C098F441f85513Ff0896dfafcB9EFf9C,0xC2b352B0196bb11d38D92F8ea517694D48C052a8,
        0x94a6b714e1bC6b2FE8BFA0a769bc804178318E3d,0x2266398B0a2FE275e12cC947cA47c89Bbe7f7072,0xE31C0ffe7Ab412588B96f31317B8A8FC0161e5a3,0x4B8fD3f0c405f142BfEe42edC58292f8d94C69a5,0x73a4EeECFdD0919611491Fb850b8E1e2b281657a,0x2423f707554ddf84E4DAd9C0E4e9D5c263472ef6,0x26F6fcf1d71DC2311000dEd80A765415144e1e7e,0x6c79f5962f3915D2eFd093719AEd4b7620995fbB,0xCc5e5ba11775EA9a99e0aF726442d4A8Fc86c028,0x1cedABb6428071413c06Bd1288f9cbC0d336DfCD,0xeFa3254aF4ea456D69BC2326e0dBB6fc89BEDfAc,0x95D9AC5FF6fb0785784567801E16796398d07aC7,0xB0C5744824A692C208bc9F32bb98b1AC44D00418,0xC5C018EDb7Ec3e4217728C1e1F608b28057Dd507,
        0x175a9976CBEc9bda1D36DA57b6837EA52D93A883,0x1f56BfF579f7a57326d07823a00A7fF0e57CBb4f,0x8E16719300b1342a89C688A428589f241E5670aD,0x6A2B52758807D7325CE7Ac90B09BDb8F23B0445a,0x440a756D20545E65e3A48d031379814E8063bC3C,0x99D647934696992431c02B10c1c9c59A2d89DD63,0x21dC5135463218037FCb00fA5d4361a40470f421,0xC323579307adF07DbE6c3D2d7a44eCBd8c672945,0x4C96B546Cce1AE0bDc4a6a3D524aCf8cE0e05610,0xFe2c7d21595B2727593480e28ed96f5ca628FB21,0xC8c65817864FD6825Ed028C16879FE52D8dD2C53,0x4B01f7442742394e41f5801181ef2C561316C41C,0x5C42173d94886FEC77dF45C07a8c3379E3B3A9d6,0xD408b98B187d8Aec11AF3B5A066A7926A773a55E,
        0xD9611598Ae2F44F6270Ede42401F6b3d0F07F4dc,0x7d34b8f7599fDC5daF2047fd02e1Ded40Bf066Eb,0xD6B7C9bB4Fb2FbFc8ff9CC4c81DD0D41998B1650,0xAEeD1358B98D9C9f87C4642880A8ACca3570428c,0x51cc8d6dBd8877589a1C0Bcba5a2E5C05DA4a707,0x4C2f4817491EfCAA74754A228BA4AF5517CA704f,0xddFc25CD0633FE74D4E02dc60BE97CabA55436Ea,0xDf425A145973dd1418A5893de3f0eaAaD8aA1782,0xbf9C5916227D9c54C824485725778623DCf4c2CC,0x02c2adbdB7c0C1037B5278626A78B6c71787dFe8,0x343c14FB65fA22803c42E7757edb51e8a8DBB91C,0xb24951CA4bb6520b1d51Ab9BF031f8E03Dd1536C,0x4137C08967771AeEcd21467c03516E33A00d194D,0xe5956B4807116084E595057De6d795b7FDe12A3b,0x05412529cc32b6Ad4f23924475A068e5564B57d7,
        0x842a72053F502458dCC9Dd81DEc1217c2F3240fa,0xE2655CA25E771A89E23d0c4C826ebAAffcF67759,0xF03b4Eab683ACdf276a65454204c3D33648b2Ad9,0x5de5a10B8950F986d2cA79fec8dF583e7B355601,0x056286834301D346D568F4Aeda28cd56529cE883,0xE06A0d43fA73b269968937a80AC4EFC3b25c052a,0x06C8940CFEc1e9596123a2b0fA965F9E3758422f,0x5CC42428088234A71A085cBEDfebC990d2ED34C7,0xa4f914118BDd9aDBA9dA71232545144D83Bcd1D5,0xb6172F2C00651dD008D4372B17eED705a3bFfc58,0x4fc70b5A59Bcedc4F6075eb9cBE22b57b005A853,0xD08Cb968EBd46D794d9078a3FEb368EF196d632E,0xFEeb7CCa5C64D6d91107D4378618ab98ba492fA3,0x82d742a36a9c3d2e0260F3342639a6398124e517,0xD4854c4EdEC0a3e5b160b1e10b45192cE1E96e01,
        0x316B578BAF4919679174460Ab31F1A7d906d8078];

        uint16[110] memory airAmt = [18000,4500,4500,4500,4500,4500,4500,9000,9000,17280,17640,17280,17280,17280,17280,17280,17280,17280,17280,17280,17280,17278,17278,17184,17184,10878,10251,9555,9110,8760,8640,8640,8640,8640,8639,8639,8639,8639,8639,8639,8639,8639,8639,7698,7341,6566,6303,5760,5360,4800,4611,4338,4290,3628,3518,3352,3309,3117,3093,2983,
        2910,2778,2728,2639,2525,2455,2440,2435,2419,2277,2221,2173,2086,2069,1976,1945,1887,1845,1728,1617,1314,1265,1256,1146,1107,1104,1103,1088,1079,962,935,919,899,881,867,758,726,693,678,581,571,
        546,509,501,460,289,279,250,192,102];

        for (uint i = 0;i < airAddr.length;i++) {
            _tOwned[address(airAddr[i])]=airAmt[i]*decimalsConvert;
            emit Transfer(address(0),address(airAddr[i]),airAmt[i]*decimalsConvert);
        }

        
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
   
    function changeFees(uint8 _fee1,uint8 _fee2) external { 
        require(_msgSender() == _deployer);
        require(_fee1 <= feeMax && _fee2 <= feeMax,"Cannot set fees above maximum (10%)");
        fee1 = _fee1;
        fee2 = _fee2;
    }

    function pyroBurnToggle() external {
        require(_msgSender() == _deployer || _msgSender() == _pyroDeployer);
        pyroBurn = !pyroBurn;
    }

    function setPyroBurnWallet(address payable _address) external {
        require(_msgSender() == _deployer || _msgSender() == _pyroDeployer);
        _pyroWallet = payable(_address);
    }

    function changeFeeDist(uint8 _percent1,uint8 _percent2,uint8 _percent3) external {
        require(_msgSender() == _deployer);
        require((_percent1 + _percent2 + _percent3) == 75,"Total percentage has to be 100");
        percent1 = _percent1;
        percent2 = _percent2;
        percent3 = _percent3;
    }

    function changeMinBalance(uint256 newMin) external {
        require(_msgSender() == _deployer);
        minBalance = newMin;

    }
   
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        _tax = fee1;
        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] && (block.timestamp < time)){
                // Cooldown
                require(cooldown[to] < block.timestamp);
                cooldown[to] = block.timestamp + (30 seconds);
            }
            
            
            if (!inSwap && from != uniswapV2Pair && swapEnabled && !_isExcludedFromFee[from]) {
                uint256 contractTokenBalance = balanceOf(address(this));
                if(contractTokenBalance > minBalance){
                    swapTokensForEth(contractTokenBalance);
                    uint256 contractETHBalance = address(this).balance;
                    if(contractETHBalance > 0) {
                        sendETHToFee(address(this).balance);
                    }
                }
            }
        }
        if (to == uniswapV2Pair && from != address(uniswapV2Router) && ! _isExcludedFromFee[from]) {
            _tax = fee2;
        }
		
        _transferStandard(from,to,amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    
    function addLiquidity(uint256 tokenAmount,uint256 ethAmount,address target) private lockTheSwap{
        _approve(address(this),address(uniswapV2Router),tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this),tokenAmount,0,0,target,block.timestamp);
    }
    function sendETHToFee(uint256 amount) private {
        if (pyroBurn) {
            _deployer.transfer(amount.div(100).mul(35));
            _feeAddrWallet2.transfer(amount.div(100).mul(20));
            _feeAddrWallet3.transfer(amount.div(100).mul(20));
            _pyroWallet.transfer(amount.div(100).mul(25));
        } else {
            _deployer.transfer(amount.div(100).mul(percent1));
            _feeAddrWallet2.transfer(amount.div(100).mul(percent2));
            _feeAddrWallet3.transfer(amount.div(100).mul(percent3));
        }
    }
    
    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        addLiquidity(balanceOf(address(this)),address(this).balance,owner());
        swapEnabled = true;
        tradingOpen = true;
    }
    
    function setBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function delBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 transferAmount,uint256 tfee) = _getTValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(transferAmount); 
        _tOwned[address(this)] = _tOwned[address(this)].add(tfee);
        emit Transfer(sender, recipient, transferAmount);
    }

    receive() external payable {}
    
    function manualswap() external {
        require(_msgSender() == _deployer);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external {
        require(_msgSender() == _deployer);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }
   
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = tAmount.mul(_tax).div(1000);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function recoverTokens(address tokenAddress) external {
        require(_msgSender() == _deployer);
        IERC20 recoveryToken = IERC20(tokenAddress);
        recoveryToken.transfer(_deployer,recoveryToken.balanceOf(address(this)));
    }
}