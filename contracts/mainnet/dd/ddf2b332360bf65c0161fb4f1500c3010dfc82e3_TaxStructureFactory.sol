/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract TaxStructureFactory is Ownable {
  event Deploy(address addr, address deployer);

  constructor () {}

  function deployTaxStructure(uint _salt, address _router) external returns (address) { 
    TaxStructure _contract = new TaxStructure{
      salt: bytes32(_salt)
    }(_msgSender(), _router);
    emit Deploy(address(_contract), msg.sender);
    return address(_contract);
  }
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IUniswapV2Pair {
    function factory() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract TaxStructure is Ownable {
    uint256 public feeDecimal = 2;
    address public routerAddress;

    string public tax1Name;
    address public tax1Wallet;
    uint256 public tax1BuyConfig;
    uint256 public tax1SellConfig;

    string public tax2Name;
    address public tax2Wallet;
    uint256 public tax2BuyConfig;
    uint256 public tax2SellConfig;

    string public tax3Name;
    address public tax3Wallet;
    uint256 public tax3BuyConfig;
    uint256 public tax3SellConfig;

    string public tax4Name;
    address public tax4Wallet;
    uint256 public tax4BuyConfig;
    uint256 public tax4SellConfig;
  
    string public tokenTaxName;
    address public tokenTaxWallet;
    uint256 public tokenTaxBuyConfig;
    uint256 public tokenTaxSellConfig;

    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public burnTaxBuyConfig;
    uint256 public burnTaxSellConfig;
  
    address public lpTokenHolder;
    uint256 public liquidityTaxBuyConfig;
    uint256 public liquidityTaxSellConfig;

    string public customTaxName;

    event TaxUpdated(
        string oldName,
        address oldWallet,
        uint256 oldBuyAmount,
        uint256 oldSellAmount,
        string newName,
        address newWallet,
        uint256 newBuyAmount,
        uint256 newSellAmount
    );

    event CustomTaxNameUpdated(
        string oldName,
        string newName
    );

    event RouterUpdated(
        address oldRouter,
        address newRouter
    );

    event FeeDecimalUpdated(
        uint256 oldDecimal,
        uint256 newDecimal
    );

    constructor (address _owner, address _router) {
      transferOwnership(_owner);
      routerAddress = _router;
    }

    // buy amounts
    function tax1BuyAmount (address _address) public view returns (uint256) {
      return tax1BuyConfig;
    }
    function tax2BuyAmount (address _address) public view returns (uint256) {
      return tax2BuyConfig;
    }
    function tax3BuyAmount (address _address) public view returns (uint256) {
      return tax3BuyConfig;
    }
    function tax4BuyAmount (address _address) public view returns (uint256) {
      return tax4BuyConfig;
    }
    function tokenTaxBuyAmount (address _address) public view returns (uint256) {
      return tokenTaxBuyConfig;
    }
    function burnTaxBuyAmount (address _address) public view returns (uint256) {
      return burnTaxBuyConfig;
    }
    function liquidityTaxBuyAmount (address _address) public view returns (uint256) {
      return liquidityTaxBuyConfig;
    }

    // sell sell amounts
    function tax1SellAmount (address _address) public view returns (uint256) {
      return tax1SellConfig;
    }
    function tax2SellAmount (address _address) public view returns (uint256) {
      return tax2SellConfig;
    }
    function tax3SellAmount (address _address) public view returns (uint256) {
      return tax3SellConfig;
    }
    function tax4SellAmount (address _address) public view returns (uint256) {
      return tax4SellConfig;
    }
    function tokenTaxSellAmount (address _address) public view returns (uint256) {
      return tokenTaxSellConfig;
    }
    function burnTaxSellAmount (address _address) public view returns (uint256) {
      return burnTaxSellConfig;
    }
    function liquidityTaxSellAmount (address _address) public view returns (uint256) {
      return liquidityTaxSellConfig;
    }

    function setRouterAddress (address _newRouterAddress) external onlyOwner {
      address _oldRouter = routerAddress;
      routerAddress = _newRouterAddress;

      emit RouterUpdated(
        _oldRouter,
        routerAddress
      );
    }

    function setTax1 (string memory _name, address _wallet, uint256 _buyAmount, uint256 _sellAmount) external onlyOwner {
      string memory _oldName = tax1Name;
      address _oldWallet = tax1Wallet;
      uint256 _oldBuyAmount = tax1BuyConfig;
      uint256 _oldSellAmount = tax1SellConfig;

      tax1Name = _name;
      tax1Wallet = _wallet;
      tax1BuyConfig = _buyAmount;
      tax1SellConfig = _sellAmount;

      emit TaxUpdated(
        _oldName,
        _oldWallet,
        _oldBuyAmount,
        _oldSellAmount,
        tax1Name,
        tax1Wallet,
        tax1BuyConfig,
        tax1SellConfig
      );
    }

    function setTax2 (string memory _name, address _wallet, uint256 _buyAmount, uint256 _sellAmount) external onlyOwner {
      string memory _oldName = tax2Name;
      address _oldWallet = tax2Wallet;
      uint256 _oldBuyAmount = tax2BuyConfig;
      uint256 _oldSellAmount = tax2SellConfig;

      tax2Name = _name;
      tax2Wallet = _wallet;
      tax2BuyConfig = _buyAmount;
      tax2SellConfig = _sellAmount;

      emit TaxUpdated(
        _oldName,
        _oldWallet,
        _oldBuyAmount,
        _oldSellAmount,
        tax2Name,
        tax2Wallet,
        tax2BuyConfig,
        tax2SellConfig
      );
    }

    function setTax3 (string memory _name, address _wallet, uint256 _buyAmount, uint256 _sellAmount) external onlyOwner  {
      string memory _oldName = tax3Name;
      address _oldWallet = tax3Wallet;
      uint256 _oldBuyAmount = tax3BuyConfig;
      uint256 _oldSellAmount = tax3SellConfig;

      tax3Name = _name;
      tax3Wallet = _wallet;
      tax3BuyConfig = _buyAmount;
      tax3SellConfig = _sellAmount;

      emit TaxUpdated(
        _oldName,
        _oldWallet,
        _oldBuyAmount,
        _oldSellAmount,
        tax3Name,
        tax3Wallet,
        tax3BuyConfig,
        tax3SellConfig
      );
    }

    function setTax4 (string memory _name, address _wallet, uint256 _buyAmount, uint256 _sellAmount) external onlyOwner {
      string memory _oldName = tax4Name;
      address _oldWallet = tax4Wallet;
      uint256 _oldBuyAmount = tax4BuyConfig;
      uint256 _oldSellAmount = tax4SellConfig;

      tax4Name = _name;
      tax4Wallet = _wallet;
      tax4BuyConfig = _buyAmount;
      tax4SellConfig = _sellAmount;

      emit TaxUpdated(
        _oldName,
        _oldWallet,
        _oldBuyAmount,
        _oldSellAmount,
        tax4Name,
        tax4Wallet,
        tax4BuyConfig,
        tax4SellConfig
      );
    }

    function setTokenTax (string memory _name, address _wallet, uint256 _buyAmount, uint256 _sellAmount) external onlyOwner {
      string memory _oldName = tokenTaxName;
      address _oldWallet = tokenTaxWallet;
      uint256 _oldBuyAmount = tokenTaxBuyConfig;
      uint256 _oldSellAmount = tokenTaxSellConfig;

      tokenTaxName = _name;
      tokenTaxWallet = _wallet;
      tokenTaxBuyConfig = _buyAmount;
      tokenTaxSellConfig = _sellAmount;

      emit TaxUpdated(
        _oldName,
        _oldWallet,
        _oldBuyAmount,
        _oldSellAmount,
        tokenTaxName,
        tokenTaxWallet,
        tokenTaxBuyConfig,
        tokenTaxSellConfig
      );
    }

    function setLiquidityTax (address _lpTokenHolder, uint256 _buyAmount, uint256 _sellAmount) external onlyOwner {
      address _oldLpTokenHolder = lpTokenHolder;
      uint256 _oldBuyAmount = liquidityTaxBuyConfig;
      uint256 _oldSellAmount = liquidityTaxSellConfig;

      lpTokenHolder = _lpTokenHolder;
      liquidityTaxBuyConfig = _buyAmount;
      liquidityTaxSellConfig = _sellAmount;

      emit TaxUpdated(
        'Liquidity Tax',
        _oldLpTokenHolder,
        _oldBuyAmount,
        _oldSellAmount,
        'Liquidity Tax',
        lpTokenHolder,
        liquidityTaxBuyConfig,
        liquidityTaxSellConfig
      );
    }

    function setBurnTax (address _burnAddress, uint256 _buyAmount, uint256 _sellAmount) external onlyOwner {
      address _oldBurnAddress = burnAddress;
      uint256 _oldBuyAmount = burnTaxBuyConfig;
      uint256 _oldSellAmount = burnTaxSellConfig;

      burnAddress = _burnAddress;
      burnTaxBuyConfig = _buyAmount;
      burnTaxSellConfig = _sellAmount;

      emit TaxUpdated(
        'Burn Tax',
        _oldBurnAddress,
        _oldBuyAmount,
        _oldSellAmount,
        'Burn Tax',
        burnAddress,
        burnTaxBuyConfig,
        burnTaxSellConfig
      );
    }

    function setCustomTaxName (string memory _name) external onlyOwner {
      string memory _oldName = customTaxName;
      customTaxName = _name;

      emit CustomTaxNameUpdated(
        _oldName,
        customTaxName
      );
    }

    function setFeeDecimal (uint256 _newDecimal) external onlyOwner {
      uint256 _oldDecimal = feeDecimal;
      feeDecimal = _newDecimal;
      
      emit FeeDecimalUpdated(
        _oldDecimal,
        feeDecimal
      );
    }

    function getBuyTaxAmounts (
      address _address
    ) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
      return (
        tax1BuyAmount(_address),
        tax2BuyAmount(_address),
        tax3BuyAmount(_address),
        tax4BuyAmount(_address),
        tokenTaxBuyAmount(_address),
        burnTaxBuyAmount(_address),
        liquidityTaxBuyAmount(_address)
      );
    }

    function getSellTaxAmounts (
      address _address
    ) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
      return (
        tax1SellAmount(_address),
        tax2SellAmount(_address),
        tax3SellAmount(_address),
        tax4SellAmount(_address),
        tokenTaxSellAmount(_address),
        burnTaxSellAmount(_address),
        liquidityTaxSellAmount(_address)
      );
    }

    function getTaxNames () external view returns (string memory, string memory, string memory, string memory, string memory, string memory, string memory) {
      return (
        tax1Name,
        tax2Name,
        tax3Name,
        tax4Name,
        tokenTaxName,
        "Burn Tax",
        "Liquidity Tax"
      );
    }

    function getTaxWallets () external view returns (address, address, address, address, address, address, address) {
      return (
        tax1Wallet,
        tax2Wallet,
        tax3Wallet,
        tax4Wallet,
        tokenTaxWallet,
        burnAddress,
        lpTokenHolder
      );
    }

    function getPair (address _token) public view returns (address) {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(routerAddress);
        IUniswapV2Factory uniswapV2Factory = IUniswapV2Factory(uniswapV2Router.factory());
        return uniswapV2Factory.getPair(uniswapV2Router.WETH(), _token);
    }

    function getReserves (address _token) external view returns (uint112, uint112, uint32) {
        IUniswapV2Pair pair = IUniswapV2Pair(getPair(_token));
        return pair.getReserves();
    }

    function getPreSwapBuyTaxAmount (address _address, uint256 customTaxAmount) external view returns (uint256) {
        uint256 taxes = tax1BuyAmount(_address) + tax2BuyAmount(_address) + tax3BuyAmount(_address) + tax4BuyAmount(_address);
        return customTaxAmount + taxes + liquidityTaxBuyAmount(_address) / 2;
    }

    function getPostSwapBuyTaxAmount (address _address) external view returns (uint256) {
        uint256 taxes = tokenTaxBuyAmount(_address) + burnTaxBuyAmount(_address);
        return taxes + liquidityTaxBuyAmount(_address) / 2;
    }

    function getPreSwapSellTaxAmount (address _address) external view returns (uint256) {
        uint256 taxes = tokenTaxSellAmount(_address) + burnTaxSellAmount(_address);
        return taxes + liquidityTaxSellAmount(_address) / 2;
    }

    function getPostSwapSellTaxAmount (address _address) external view returns (uint256) {
        uint256 taxes = tax1SellAmount(_address) + tax2SellAmount(_address) + tax3SellAmount(_address) + tax4SellAmount(_address);
        return taxes + liquidityTaxSellAmount(_address) / 2;
    }

    function withdrawEthToOwner (uint256 _amount) external onlyOwner {
        payable(_msgSender()).transfer(_amount);
    }

    function withdrawTokenToOwner(address tokenAddress, uint256 amount) external onlyOwner {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(balance >= amount, "Insufficient token balance");

        IERC20(tokenAddress).transfer(_msgSender(), amount);
    }

    receive() external payable {}
}