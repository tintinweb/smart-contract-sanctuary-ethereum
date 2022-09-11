/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.12;

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

interface IERC1155 {
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
}

/**
 * @dev Interface of the Pawthereum contract.
 */
interface Pawthereum {
    function _isPurrEnabled() external view returns (bool);
}

contract PawthTaxStructure is Ownable {
    Pawthereum private pawthereum;

    // will respect nft1155 holding benefits if on and ignore if off
    bool public respect1155 = true;
    // the address of the nft that needs to be held to reap nft1155HoldFactor benefits
    address public nft1155BenefitAddress = 0xA9480E2e4bA1Caf3D67e98FeB96e57Caf5Ca7768;
    // the id of the 1155 nft that needs to be held to reap nft1155HoldFactor benefits
    uint256 public nft1155BenefitId = 0;
    // 5000 is a halving of pawswap fees if holding erc-1155 nft
    uint256 public nft1155HoldFactor = 5000;

    uint256 public constant feeDecimal = 2;
    uint256 private constant feeDecimalPlusTwo = 4;
    address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    string public tax1Name = "Marketing Tax";
    address public tax1Wallet = 0x16b1db77b60C8d8b6eCea0fa4E0481E9f53C9Ba1;
    uint256 public tax1BuyAmountConfig = 50;
    uint256 public tax1SellAmountConfig = 50;

    string public tax2Name = "Charity Tax";
    address public tax2Wallet = 0xf4A22C530e8cC64770C4eDb5766D26F8926E20bd;
    uint256 public tax2BuyAmountConfig = 50;
    uint256 public tax2SellAmountConfig = 50;

    string public tax3Name = "Buy Back and Burn Tax";
    address public tax3Wallet = 0x16b1db77b60C8d8b6eCea0fa4E0481E9f53C9Ba1;
    uint256 public tax3BuyAmountConfig = 50;
    uint256 public tax3SellAmountConfig = 50;
  
    string public tax4Name;
    address public tax4Wallet = 0x9036464e4ecD2d40d21EE38a0398AEdD6805a09B;
    uint256 public tax4BuyAmountConfig;
    uint256 public tax4SellAmountConfig;
  
    string public tokenTaxName;
    address public tokenTaxWallet = 0x445664D66C294F49bb55A90d3c30BCAB0F9502A9;
    uint256 public tokenTaxBuyAmountConfig;
    uint256 public tokenTaxSellAmountConfig;

    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public burnTaxBuyAmountConfig;
    uint256 public burnTaxSellAmountConfig;
  
    address public lpTokenHolder = 0x16b1db77b60C8d8b6eCea0fa4E0481E9f53C9Ba1;
    uint256 public liquidityTaxBuyAmountConfig = 50;
    uint256 public liquidityTaxSellAmountConfig = 50;

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

    constructor (address _pawthereum, address _router) {
      pawthereum = Pawthereum(_pawthereum);
      routerAddress = _router;
    }

    function holds1155 (address _address) internal view returns (bool) {
      return IERC1155(nft1155BenefitAddress).balanceOf(_address, nft1155BenefitId) > 0;
    }

    function tax1 (address _address) public view returns (uint256, address) {
      return (tax1BuyAmount(_address), tax1Wallet);
    }

    function tax2 (address _address) public view returns (uint256, address) {
      return (tax2BuyAmount(_address), tax2Wallet);
    }

    // marketing buy fee
    function tax1BuyAmount(address _address) public view returns (uint256) {
        uint256 _fee = tax1BuyAmountConfig;
        if (respect1155 && holds1155(_address)) {
          _fee = _fee * nft1155HoldFactor /  10**feeDecimalPlusTwo;
        }
        return _fee;
    }

    // marketing sell fee
    function tax1SellAmount(address _address) public view returns (uint256) {
        uint256 _fee = tax1SellAmountConfig;
        if (respect1155 && holds1155(_address)) {
          _fee = _fee * nft1155HoldFactor /  10**feeDecimalPlusTwo;
        }
        return _fee;
    }

    // charity buy fee
    function tax2BuyAmount(address _address) public view returns (uint256) {
        uint256 _fee = tax2BuyAmountConfig;
        if (respect1155 && holds1155(_address)) {
          _fee = _fee * nft1155HoldFactor / 10**feeDecimalPlusTwo;
        }
        return _fee;
    }

    // charity sell fee
    function tax2SellAmount(address _address) public view returns (uint256) {
        uint256 _fee = tax2SellAmountConfig;
        if (respect1155 && holds1155(_address)) {
          _fee = _fee * nft1155HoldFactor /  10**feeDecimalPlusTwo;
        }
        return _fee;
    }
  
    // tax buy fee
    function tax3BuyAmount(address _address) public view returns (uint256) {
        uint256 _fee = tax3BuyAmountConfig;
        if (respect1155 && holds1155(_address)) {
          _fee = _fee * nft1155HoldFactor /  10**feeDecimalPlusTwo;
        }
        return _fee;
    }

    // tax sell fee
    function tax3SellAmount(address _address) public view returns (uint256) {
        uint256 _fee = tax3SellAmountConfig;
        if (respect1155 && holds1155(_address)) {
          _fee = _fee * nft1155HoldFactor /  10**feeDecimalPlusTwo;
        }
        return _fee;
    }

    // tax buy fee
    function tax4BuyAmount(address _address) public view returns (uint256) {
        uint256 _fee = tax4BuyAmountConfig;
        if (respect1155 && holds1155(_address)) {
          _fee = _fee * nft1155HoldFactor /  10**feeDecimalPlusTwo;
        }
        return _fee;
    }

    // tax sell fee
    function tax4SellAmount(address _address) public view returns (uint256) {
        uint256 _fee = tax4SellAmountConfig;
        if (respect1155 && holds1155(_address)) {
          _fee = _fee * nft1155HoldFactor /  10**feeDecimalPlusTwo;
        }
        return _fee;
    }

    // staking buy fee
    function tokenTaxBuyAmount(address _address) public view returns (uint256) {
        uint256 _fee = tokenTaxBuyAmountConfig;
        if (respect1155 && holds1155(_address)) {
          _fee = _fee * nft1155HoldFactor /  10**feeDecimalPlusTwo;
        }
        return _fee;
    }

    // staking sell fee
    function tokenTaxSellAmount(address _address) public view returns (uint256) {
        uint256 _fee = tokenTaxSellAmountConfig;
        if (respect1155 && holds1155(_address)) {
          _fee = _fee * nft1155HoldFactor /  10**feeDecimalPlusTwo;
        }
        return _fee;
    }

    // liquidity buy fee
    function liquidityTaxBuyAmount(address _address) public view returns (uint256) {
        uint256 _fee = liquidityTaxBuyAmountConfig;
        if (respect1155 && holds1155(_address)) {
          _fee = _fee * nft1155HoldFactor /  10**feeDecimalPlusTwo;
        }
        return _fee;
    }

    // liquidity sell fee
    function liquidityTaxSellAmount(address _address) public view returns (uint256) {
        uint256 _fee = liquidityTaxSellAmountConfig;
        if (respect1155 && holds1155(_address)) {
          _fee = _fee * nft1155HoldFactor /  10**feeDecimalPlusTwo;
        }
        return _fee;
    }

    // burn buy fee
    function burnTaxBuyAmount(address _address) public view returns (uint256) {
        uint256 _fee = burnTaxBuyAmountConfig;
        if (respect1155 && holds1155(_address)) {
          _fee = _fee * nft1155HoldFactor /  10**feeDecimalPlusTwo;
        }
        return _fee;
    }

    // burn sell fee
    function burnTaxSellAmount(address _address) public view returns (uint256) {
        uint256 _fee = burnTaxSellAmountConfig;
        if (respect1155 && holds1155(_address)) {
          _fee = _fee * nft1155HoldFactor /  10**feeDecimalPlusTwo;
        }
        return _fee;
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
      uint256 _oldBuyAmount = tax1BuyAmountConfig;
      uint256 _oldSellAmount = tax1SellAmountConfig;

      tax1Name = _name;
      tax1Wallet = _wallet;
      tax1BuyAmountConfig = _buyAmount;
      tax1SellAmountConfig = _sellAmount;

      emit TaxUpdated(
        _oldName,
        _oldWallet,
        _oldBuyAmount,
        _oldSellAmount,
        tax1Name,
        tax1Wallet,
        tax1BuyAmountConfig,
        tax1SellAmountConfig
      );
    }

    function setTax2 (string memory _name, address _wallet, uint256 _buyAmount, uint256 _sellAmount) external onlyOwner {
      string memory _oldName = tax2Name;
      address _oldWallet = tax2Wallet;
      uint256 _oldBuyAmount = tax2BuyAmountConfig;
      uint256 _oldSellAmount = tax2SellAmountConfig;

      tax2Name = _name;
      tax2Wallet = _wallet;
      tax2BuyAmountConfig = _buyAmount;
      tax2SellAmountConfig = _sellAmount;

      emit TaxUpdated(
        _oldName,
        _oldWallet,
        _oldBuyAmount,
        _oldSellAmount,
        tax2Name,
        tax2Wallet,
        tax2BuyAmountConfig,
        tax2SellAmountConfig
      );
    }

    function setTax3 (string memory _name, address _wallet, uint256 _buyAmount, uint256 _sellAmount) external onlyOwner  {
      string memory _oldName = tax3Name;
      address _oldWallet = tax3Wallet;
      uint256 _oldBuyAmount = tax3BuyAmountConfig;
      uint256 _oldSellAmount = tax3SellAmountConfig;

      tax3Name = _name;
      tax3Wallet = _wallet;
      tax3BuyAmountConfig = _buyAmount;
      tax3SellAmountConfig = _sellAmount;

      emit TaxUpdated(
        _oldName,
        _oldWallet,
        _oldBuyAmount,
        _oldSellAmount,
        tax3Name,
        tax3Wallet,
        tax3BuyAmountConfig,
        tax3SellAmountConfig
      );
    }

    function setTax4 (string memory _name, address _wallet, uint256 _buyAmount, uint256 _sellAmount) external onlyOwner {
      string memory _oldName = tax4Name;
      address _oldWallet = tax4Wallet;
      uint256 _oldBuyAmount = tax4BuyAmountConfig;
      uint256 _oldSellAmount = tax4SellAmountConfig;

      tax4Name = _name;
      tax4Wallet = _wallet;
      tax4BuyAmountConfig = _buyAmount;
      tax4SellAmountConfig = _sellAmount;

      emit TaxUpdated(
        _oldName,
        _oldWallet,
        _oldBuyAmount,
        _oldSellAmount,
        tax4Name,
        tax4Wallet,
        tax4BuyAmountConfig,
        tax4SellAmountConfig
      );
    }

    function setTokenTax (string memory _name, address _wallet, uint256 _buyAmount, uint256 _sellAmount) external onlyOwner {
      string memory _oldName = tokenTaxName;
      address _oldWallet = tokenTaxWallet;
      uint256 _oldBuyAmount = tokenTaxBuyAmountConfig;
      uint256 _oldSellAmount = tokenTaxSellAmountConfig;

      tokenTaxName = _name;
      tokenTaxWallet = _wallet;
      tokenTaxBuyAmountConfig = _buyAmount;
      tokenTaxSellAmountConfig = _sellAmount;

      emit TaxUpdated(
        _oldName,
        _oldWallet,
        _oldBuyAmount,
        _oldSellAmount,
        tokenTaxName,
        tokenTaxWallet,
        tokenTaxBuyAmountConfig,
        tokenTaxSellAmountConfig
      );
    }

    function setLiquidityTax (address _lpTokenHolder, uint256 _buyAmount, uint256 _sellAmount) external onlyOwner {
      address _oldLpTokenHolder = lpTokenHolder;
      uint256 _oldBuyAmount = liquidityTaxBuyAmountConfig;
      uint256 _oldSellAmount = liquidityTaxSellAmountConfig;

      lpTokenHolder = _lpTokenHolder;
      liquidityTaxBuyAmountConfig = _buyAmount;
      liquidityTaxSellAmountConfig = _sellAmount;

      emit TaxUpdated(
        'Liquidity Tax',
        _oldLpTokenHolder,
        _oldBuyAmount,
        _oldSellAmount,
        'Liquidity Tax',
        lpTokenHolder,
        liquidityTaxBuyAmountConfig,
        liquidityTaxSellAmountConfig
      );
    }

    function setBurnTax (address _burnAddress, uint256 _buyAmount, uint256 _sellAmount) external onlyOwner {
      address _oldBurnAddress = burnAddress;
      uint256 _oldBuyAmount = burnTaxBuyAmountConfig;
      uint256 _oldSellAmount = burnTaxSellAmountConfig;

      burnAddress = _burnAddress;
      burnTaxBuyAmountConfig = _buyAmount;
      burnTaxSellAmountConfig = _sellAmount;

      emit TaxUpdated(
        'Burn Tax',
        _oldBurnAddress,
        _oldBuyAmount,
        _oldSellAmount,
        'Burn Tax',
        burnAddress,
        burnTaxBuyAmountConfig,
        burnTaxSellAmountConfig
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

    function setPawthereum (address _pawthereum) external onlyOwner {
      pawthereum = Pawthereum(_pawthereum);
    }

    function setNft1155Config (bool _respect1155, uint256 _nft1155HoldFactor, address _nftAddress, uint _nftId) external onlyOwner {
      respect1155 = _respect1155;
      nft1155BenefitAddress = _nftAddress;
      nft1155BenefitId = _nftId;
      nft1155HoldFactor = _nft1155HoldFactor;
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