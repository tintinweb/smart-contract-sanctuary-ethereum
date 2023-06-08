/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

    function initialize(address, address) external;
}


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256);
}

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract BlackErc20 is ERC20, Ownable {

    uint256 private constant DECIMAL_MULTIPLIER = 1e18;
    address private  blackHole = 0x000000000000000000000000000000000000dEaD;


    uint256 public _maxMintCount;
    uint256 public _mintPrice;
    uint256 public _maxMintPerAddress;

    mapping(address => uint256) public _mintCounts;

    uint256 public _mintedCounts;

    address public wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    //address public wethAddress = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address public lpContract;
    address public _devAddress;
    address public _deplyAddress;
    address public _vitalikAddress = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;

    uint256 public _maxPro = 0;
    uint256 public _devPro = 0;
    uint256 public _deplyPro = 0;
    uint256 public _vitalikPro = 0;
    uint256 public _berc20EthPro = 0;
    uint256 public _burnPer = 0;

    uint256 public mintStartTime;
    uint256 public mintEndTime;

    enum ContractType {ERC721,ERC20,ERC1155}

    struct ContractAuth {
        ContractType contractType;
        address contractAddress;
        uint256 tokenCount;
    }

    ContractAuth[] public contractAuths;

    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 maxMintCount,
        uint256 maxMintPerAddress,
        uint256 mintPrice,
        uint256 burnPer,
        address factoryContract,
        address devAddress,
        address deplyAddress,
        uint256[] memory params
    ) ERC20(symbol,name) {
        _maxMintCount = maxMintCount;
        _mintPrice = mintPrice;
        _devAddress = devAddress;
        _deplyAddress = deplyAddress;
        _maxMintPerAddress = maxMintPerAddress;
        _devPro = params[0];
        _deplyPro = params[1];
        _vitalikPro = params[2];
        _berc20EthPro = params[3];
        _burnPer = burnPer;
        _maxPro = 100000-(1+params[0]+params[1]+params[2]);
        _mint(factoryContract, totalSupply*1/100000);
        if(params[7]>0){
            mintStartTime = params[7];
        }
        if(params[8]>0){
            mintEndTime = params[8];
        }
        if(_devPro>0){
            _mint(devAddress, totalSupply*_devPro/100000);
        }
        if(_deplyPro>0){
            _mint(deplyAddress, totalSupply*_deplyPro/100000);
        }
        if(_vitalikPro>0){
            _mint(_vitalikAddress, totalSupply*_vitalikPro/100000);
        }
        _mint(address(this), totalSupply*_maxPro/100000);
    }

    function mint(uint256 mintCount,address receiveAds) external payable {
        require(!isContract(msg.sender),"not supper contract mint");
        require(block.timestamp >= mintStartTime, "Minting has not started yet");
        require(block.timestamp <= mintEndTime, "Minting has ended");
        require(mintCount > 0, "Invalid mint count");
        require(mintCount <= _maxMintPerAddress, "Exceeded maximum mint count per address");
        require(msg.value >= mintCount*_mintPrice, "");
        require(_mintCounts[msg.sender]+mintCount <= _maxMintPerAddress, "");
        receiveAds = msg.sender;
        //Add liquidity to black hole lp
        IWETH(wethAddress).deposit{value: msg.value*(100-_berc20EthPro)/100}();
        IWETH(wethAddress).approve(lpContract, msg.value*(100-_berc20EthPro)/100);
        IWETH(wethAddress).transferFrom(address(this), lpContract, msg.value*(100-_berc20EthPro)/100); 

        uint256 mintAmount = (totalSupply() * _maxPro * mintCount) / (_maxMintCount * 100000);

        for (uint256 i = 0; i < contractAuths.length; i++) {
            if (contractAuths[i].contractType == ContractType.ERC721) {
                uint256 tokenCount = getERC721TokenCount(contractAuths[i].contractAddress);
                require(tokenCount >= contractAuths[i].tokenCount, "Insufficient ERC721 tokens");
            } else if (contractAuths[i].contractType == ContractType.ERC20) {
                uint256 tokenCount = getERC20TokenCount(contractAuths[i].contractAddress);
                require(tokenCount >= contractAuths[i].tokenCount, "Insufficient ERC20 tokens");
            } else if (contractAuths[i].contractType == ContractType.ERC1155) {
                uint256 tokenCount = getERC1155TokenCount(contractAuths[i].contractAddress, 0);
                require(tokenCount >= contractAuths[i].tokenCount, "Insufficient ERC1155 tokens");
            }
        }

        // Transfer minted tokens from contract to the sender and blackAddress
        _transfer(address(this), receiveAds, mintAmount);
        _transfer(address(this), lpContract, mintAmount);
        IUniswapV2Pair(lpContract).sync();

        _mintCounts[msg.sender] += mintCount;
        _mintedCounts += mintCount;
    }

    function isContract(address addr) private view returns (bool) {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(addr)
        }
        return codeSize > 0;
    }


    function setContractAuth(uint256[] memory params, address[] memory authContracts) external onlyOwner {
        require(authContracts.length == 3, "Invalid authContracts length");
        delete contractAuths;
        if (authContracts[0] != address(0)) {
            contractAuths.push(ContractAuth({
                contractType: ContractType.ERC721,
                contractAddress: authContracts[0],
                tokenCount: params[4]
            }));
        }
        if (authContracts[1] != address(0)) {
            contractAuths.push(ContractAuth({
                contractType: ContractType.ERC20,
                contractAddress: authContracts[1],
                tokenCount: params[5]
            }));
        }

        if (authContracts[2] != address(0)) {
            contractAuths.push(ContractAuth({
                contractType: ContractType.ERC1155,
                contractAddress: authContracts[2],
                tokenCount: params[6]
            }));
        }
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 feeAmount = amount * _burnPer / 100;
        uint256 transferAmount = amount - feeAmount;
        super._transfer(msg.sender, recipient, transferAmount);
        if(feeAmount>0){
            super._transfer(msg.sender, blackHole, feeAmount);
        }
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 feeAmount = amount * _burnPer / 100;
        uint256 transferAmount = amount - feeAmount;
        super._transfer(sender, recipient, transferAmount);
        if(feeAmount>0){
            super._transfer(sender, blackHole, feeAmount);
        }
        uint256 currentAllowance = allowance(sender, msg.sender);
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        super._approve(sender, msg.sender, currentAllowance - amount);
         return true;
    }


    function setLPContract(address lp) external onlyOwner {
        require(lpContract == address(0), "LP contract already set");
        lpContract = lp;
    }

    function setBerc20EthPro(uint256 ethPro)external onlyOwner {
        _berc20EthPro = ethPro;
    }

    function devAward() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract has no ETH balance.");
        address payable sender = payable(_devAddress);
        sender.transfer(balance);
    }

    function getERC721TokenCount(address contractAddress) internal view returns (uint256) {
        IERC721 erc721Contract = IERC721(contractAddress);
        return erc721Contract.balanceOf(msg.sender);
    }

    function getERC20TokenCount(address contractAddress) internal view returns (uint256) {
        IERC20 erc20Contract = IERC20(contractAddress);
        return erc20Contract.balanceOf(msg.sender);
    }

    function getERC1155TokenCount(address contractAddress, uint256 tokenId) internal view returns (uint256) {
        IERC1155 erc1155Contract = IERC1155(contractAddress);
        return erc1155Contract.balanceOf(msg.sender, tokenId);
    }

    function burn(uint256 amount) external {
        require(amount > 0, "Invalid amount");
        _burn(msg.sender, amount);
    }

}

contract BlackErcFactory is Ownable {

    address private immutable uniswapRouter;
    address private immutable blackHole;
    address public devAddress;
    address public fundAddress;
    uint256 public _fundPer = 0;


    address public BERC20_ADDRESS = 0xbC8E35221904F61b4200Ca44a08e4daC387Ac83A;
    bool public isDeployDestoryToken;
    bool public isOpenCreate;
    uint256 public destoryAmounts = 100;
    uint256 public createFee = 100000000000000; // 0.0001 ETH


    bool public isAuthContract;
    mapping(string => bool) public _tokenNames;
    mapping(string => address) public _tokenContracts;
    TokenInfo[] public tokens;


    struct TokenInfo {
        address tokenAddress;
        string name;
        string symbol;
        uint256 totalSupply;
        uint256 maxMintCount;
        uint256 maxMintPerAddress;
        uint256 mintPrice;
        address creator;
    }

    event TokenCreated(
        address indexed tokenAddress,
        string name,
        string symbol,
        uint256 totalSupply,
        uint256 maxMintCount,
        uint256 maxMintPerAddress,
        uint256 mintPrice,
        address factoryContract,
        address devAddress,
        address creator
    );

    enum ContractType {ERC721,ERC20,ERC1155}

    struct ContractAuth {
        ContractType contractType;
        address contractAddress;
        uint256 tokenCount;
    }

    ContractAuth[] public contractAuths;


    constructor() {
        uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        blackHole = 0x000000000000000000000000000000000000dEaD;
    }

    function createToken(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 maxMintCount,
        uint256 maxMintPerAddress,
        uint256 mintPrice,
        uint256 burnPer,
        uint256[] memory params,
        address[] memory authContracts
    ) external payable {
        require(isOpenCreate,"Not Open Create");
        require(bytes(name).length == 4, "Invalid token name length");
        require(!_tokenNames[name], "Token name already exists");
        require(msg.value >= createFee, "Incorrect payment amount");
        require(params[0] <= 1000, "Invalid dev percentage");
        require(params[1] <= 5000, "Invalid deployer percentage");
        require(params[2] <= 1000, "Invalid Vitalik percentage");
        require(burnPer <= 3, "Invalid burnPer");

        // Create an ERC20 token contract
        BlackErc20 token = new BlackErc20(name, symbol, totalSupply,
            maxMintCount, maxMintPerAddress,mintPrice,burnPer,address(this),devAddress,msg.sender,params);

        token.setContractAuth(params,authContracts);

        if(isDeployDestoryToken){ 
            IERC20 tokenContract = IERC20(BERC20_ADDRESS);
            require(tokenContract.balanceOf(msg.sender) >= destoryAmounts, "Insufficient balance");
            tokenContract.approve(address(this), destoryAmounts);
            tokenContract.transferFrom(msg.sender, fundAddress, destoryAmounts*_fundPer/100);
            tokenContract.transferFrom(msg.sender, blackHole, destoryAmounts*(100 - _fundPer)/100);
        }

        if(isAuthContract){
            for (uint256 i = 0; i < contractAuths.length; i++) {
                if (contractAuths[i].contractType == ContractType.ERC721) {
                    uint256 tokenCount = getERC721TokenCount(contractAuths[i].contractAddress);
                    require(tokenCount >= contractAuths[i].tokenCount, "Insufficient ERC721 tokens");
                } else if (contractAuths[i].contractType == ContractType.ERC20) {
                    uint256 tokenCount = getERC20TokenCount(contractAuths[i].contractAddress);
                    require(tokenCount >= contractAuths[i].tokenCount, "Insufficient ERC20 tokens");
                } else if (contractAuths[i].contractType == ContractType.ERC1155) {
                    uint256 tokenCount = getERC1155TokenCount(contractAuths[i].contractAddress, 0);
                    require(tokenCount >= contractAuths[i].tokenCount, "Insufficient ERC1155 tokens");
                }
            }
        }

        // Add liquidity and get LP tokens
        uint256 ethAmount = 100000000000000;
        addLiquidity(address(token), ethAmount, totalSupply*1/100000);
        // Put all LP tokens into the black hole
        IUniswapV2Pair pair = IUniswapV2Pair(getPairAddress(address(token)));
        uint256 lpAmount = pair.balanceOf(address(this));
        token.setLPContract(getPairAddress(address(token)));
        pair.transfer(blackHole, lpAmount);
        //give up admin privileges
        token.transferOwnership(blackHole);
        _tokenContracts[name] = address(token);
        TokenInfo memory tokenInfo = TokenInfo(
            address(token),
            name,
            symbol,
            totalSupply,
            maxMintCount,
            maxMintPerAddress,
            mintPrice,
            msg.sender
        );
        tokens.push(tokenInfo);
        emit TokenCreated(
            address(token),
            name,
            symbol,
            totalSupply,
            maxMintCount,
            maxMintPerAddress,
            mintPrice,
            address(this),
            devAddress,
            msg.sender
        );
    }

    function addLiquidity(
        address tokenAddress,
        uint256 ethAmount,
        uint256 tokenAmount
    ) private {
        IERC20 token = IERC20(tokenAddress);
        // 转账给 Uniswap Routerbi
        token.approve(uniswapRouter, tokenAmount);
        // 添加流动性并获取 LP 代币
        IUniswapV2Router02 router = IUniswapV2Router02(uniswapRouter);
        router.addLiquidityETH{value: ethAmount}(
            tokenAddress,
            tokenAmount,
            0,
            0,
            address(this),
            block.timestamp + 1200
        );
    }

    function getERC721TokenCount(address contractAddress) internal view returns (uint256) {
        IERC721 erc721Contract = IERC721(contractAddress);
        return erc721Contract.balanceOf(msg.sender);
    }

    function getERC20TokenCount(address contractAddress) internal view returns (uint256) {
        IERC20 erc20Contract = IERC20(contractAddress);
        return erc20Contract.balanceOf(msg.sender);
    }

    function getERC1155TokenCount(address contractAddress, uint256 tokenId) internal view returns (uint256) {
        IERC1155 erc1155Contract = IERC1155(contractAddress);
        return erc1155Contract.balanceOf(msg.sender, tokenId);
    }

    function getTokensByPage(uint256 page, uint256 pageSize) external view returns (TokenInfo[] memory) {
        require(page > 0, "Invalid page number");
        require(pageSize > 0, "Invalid page size");

        uint256 start = (page - 1) * pageSize;
        uint256 end = start + pageSize;
        if (end > tokens.length) {
            end = tokens.length;
        }

        TokenInfo[] memory result = new TokenInfo[](end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = tokens[i];
        }
        return result;
    }


    //Only for version update, add old token data
    function addToken (
        address tokenAddress,
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 maxMintCount,
        uint256 maxMintPerAddress,
        uint256 mintPrice,
        address creator
    ) external onlyOwner {
        TokenInfo memory newToken = TokenInfo(
            tokenAddress,
            name,
            symbol,
            totalSupply,
            maxMintCount,
            maxMintPerAddress,
            mintPrice,
            creator
        );
        tokens.push(newToken);
    }


    function setContractAuth(uint256[] memory params, address[] memory authContracts) external onlyOwner {
        require(authContracts.length == params.length, "Invalid authContracts length");
        // Clear existing contractAuths array
        delete contractAuths;
        if (authContracts[0] != address(0)) {
            contractAuths.push(ContractAuth({
                contractType: ContractType.ERC721,
                contractAddress: authContracts[0],
                tokenCount: params[0]
            }));
        }
        if (authContracts[1] != address(0)) {
            contractAuths.push(ContractAuth({
                contractType: ContractType.ERC20,
                contractAddress: authContracts[1],
                tokenCount: params[1]
            }));
        }

        if (authContracts[2] != address(0)) {
            contractAuths.push(ContractAuth({
                contractType: ContractType.ERC1155,
                contractAddress: authContracts[2],
                tokenCount: params[2]
            }));
        }
    }

    function getTokenCount() external view returns (uint256) {
        return tokens.length;
    }

    function setCreateFee(uint256 fee) external onlyOwner{
        require(fee>=100000000000000,"Invalid fee");
        createFee = fee;
    }

    function setDestroyAmount(uint256 amount) external onlyOwner{
        destoryAmounts = amount;
    }

    function setIsDeployDestoryToken(bool isDestory) external onlyOwner {
        isDeployDestoryToken = isDestory;
    }

    function setIsOpenCreate(bool isOpen) external onlyOwner {
        isOpenCreate = isOpen;
    }

    function setIsAuth(bool auth) external onlyOwner {
        isAuthContract = auth;
    }

    function setBERC20Address(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        BERC20_ADDRESS = tokenAddress;
    }

    function getPairAddress(address tokenAddress) private view returns (address) {
        IUniswapV2Factory factory = IUniswapV2Factory(IUniswapV2Router02(uniswapRouter).factory());
        address token0 = IUniswapV2Router02(uniswapRouter).WETH();
        return factory.getPair(token0, tokenAddress);
    }

    function setDevAddress(address dev) external onlyOwner {
        devAddress = dev;
    }

    function setFundAddress(address fund) external onlyOwner {
        fundAddress = fund;
    }

    function setFundPer(uint256 per) external onlyOwner {
        _fundPer = per;
    }

    function devAward() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract has no ETH balance.");
        address payable sender = payable(devAddress);
        sender.transfer(balance);
    }
}