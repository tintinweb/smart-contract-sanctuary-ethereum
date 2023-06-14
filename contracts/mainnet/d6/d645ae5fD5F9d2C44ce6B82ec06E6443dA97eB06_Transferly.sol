/*

TRANSFERLY

Website: 
https://www.transferly.tech/

*/


// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.18;

interface IERC20 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Permit is IERC20 {
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}

contract Ownable {
  address private _owner;
  address private _previousOwner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }
}

interface IUniswapV2Factory {
  function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function factory() external pure returns (address);
  function WETH() external pure returns (address);
}

interface ITransferly {
  error AmountExceedAllowance();
  error ExpiredDeadline();
  error InvalidSignature();
  error ZeroAddress();
  error TradingClose();
  error MaxTx();
}

contract Transferly is ITransferly, IERC20Permit, Ownable {
  /*///////////////////////////////////////////////////////////////
                            Mappings
  //////////////////////////////////////////////////////////////*/
  mapping(address => uint256) private _balance;
  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => bool) private _walletExcluded;
  mapping(address => uint256) public nonces;

  /*///////////////////////////////////////////////////////////////
                            Constants
  //////////////////////////////////////////////////////////////*/
  string public constant name = "Transferly";
  string public constant symbol = "TFY";
  uint8 public constant decimals = 18;
  uint256 public constant totalSupply = 10 ** 7 * 10 ** decimals;
  uint256 public constant MIN_SWAP = 4000 * 10 ** decimals; // MINSWAP = 0,04%
  uint256 private constant _ONE_PERCENT = 100_000 * 10 ** decimals;
  bytes32 public constant PERMIT_TYPEHASH =
    keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');

  /*///////////////////////////////////////////////////////////////
                        Private State Variables
  //////////////////////////////////////////////////////////////*/
  address payable private _treasuryAddress;
  IUniswapV2Router02 private _uniswapV2Router;
  uint256 private _launchBlock;
  uint256 private _tax;
  bool private _launch = false;
  uint256 private _buyValue = 0;

  /*///////////////////////////////////////////////////////////////
                        Public State Variables
  //////////////////////////////////////////////////////////////*/
  uint256 public buyTax = 25;
  uint256 public sellTax = 60;
  uint256 public maxTxAmount = _ONE_PERCENT * 2;
  address public uniswapV2Pair;
  bytes32 public DOMAIN_SEPARATOR;

  /*///////////////////////////////////////////////////////////////
                            Constructor
  //////////////////////////////////////////////////////////////*/
  constructor(address[] memory _wallets) {
    // Uni info
    _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

    // Treasury address logic
    _treasuryAddress = payable(_wallets[0]);
    for (uint256 _i; _i < _wallets.length;) {
      _walletExcluded[_wallets[_i]] = true;
      unchecked {
        ++_i;
      }
    }

    // Total supply
    _balance[msg.sender] = totalSupply;
    _walletExcluded[msg.sender] = true;
    _walletExcluded[address(this)] = true;

    // Emit
    emit Transfer(address(0), _msgSender(), totalSupply);

    // Assembly low gas get chain
    uint256 _chainId;
    assembly {
      _chainId := chainid()
    }

    // Domain separator hash
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
        keccak256(bytes(name)),
        keccak256('1'),
        _chainId,
        address(this)
      )
    );
  }

  /*///////////////////////////////////////////////////////////////
                        External Functions
  //////////////////////////////////////////////////////////////*/
  function balanceOf(address _account) public view override returns (uint256 _amount) {
    _amount = _balance[_account];
  }

  function transfer(address _recipient, uint256 _amount) public override returns (bool _result) {
    _transfer(_msgSender(), _recipient, _amount);
    _result = true;
  }

  function allowance(address _owner, address _spender) public view override returns (uint256 _amount) {
    _amount = _allowances[_owner][_spender];
  }

  function approve(address _spender, uint256 _amount) public override returns (bool _result) {
    _approve(_msgSender(), _spender, _amount);
    _result = true;
  }

  function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool _result) {
    _transfer(_sender, _recipient, _amount);

    if (_amount > _allowances[_sender][_msgSender()]) revert AmountExceedAllowance();
    _approve(_sender, _msgSender(), _amount);
    _result = true;
  }

  function permit(
    address _owner,
    address _spender,
    uint256 _value,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external override {
    if (block.timestamp > _deadline) revert ExpiredDeadline();

    bytes32 _structHash = keccak256(abi.encode(PERMIT_TYPEHASH, _owner, _spender, _value, nonces[_owner]++, _deadline));
    bytes32 _hash = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, _structHash));
    address _signer = ecrecover(_hash, _v, _r, _s);
    if (_signer != _owner) revert InvalidSignature();

    _approve(_owner, _spender, _value);
  }

  function enableTrading() external onlyOwner {
    _launch = true;
    _launchBlock = block.number;
  }

  function addExcludedWallet(address _wallet) external onlyOwner {
    _walletExcluded[_wallet] = true;
  }

  function removeLimits() external onlyOwner {
    maxTxAmount = totalSupply;
  }

  function changeTax(uint256 _newBuyTax, uint256 _newSellTax) external onlyOwner {
    buyTax = _newBuyTax;
    sellTax = _newSellTax;
  }

  function changeBuyValue(uint256 newBuyValue) external onlyOwner {
    _buyValue = newBuyValue;
  }

  function manualSendBalance() external {
    if (msg.sender != _treasuryAddress) revert();
    uint256 _contractETHBalance = address(this).balance;
    _treasuryAddress.transfer(_contractETHBalance);

    uint256 _contractBalance = balanceOf(address(this));
    _treasuryAddress.transfer(_contractBalance);
  }

  function manualSwapTokens() external {
    if (msg.sender != _treasuryAddress) revert();
    uint256 _contractBalance = balanceOf(address(this));
    _swapTokensForEth(_contractBalance);
  }

  /*///////////////////////////////////////////////////////////////
                        Private Functions
  //////////////////////////////////////////////////////////////*/
  function _approve(address _owner, address _spender, uint256 _amount) private {
    if (_owner == address(0) || _spender == address(0)) revert ZeroAddress();
    _allowances[_owner][_spender] = _amount;
    emit Approval(_owner, _spender, _amount);
  }

  function _tokenTransfer(address _from, address _to, uint256 _amount) private {
    uint256 _taxTokens = (_amount * _tax) / 100;
    uint256 _transferAmount = _amount - _taxTokens;

    _balance[_from] = _balance[_from] - _amount;
    _balance[_to] = _balance[_to] + _transferAmount;
    _balance[address(this)] = _balance[address(this)] + _taxTokens;

    emit Transfer(_from, _to, _transferAmount);
  }

  function _transfer(address _from, address _to, uint256 _amount) private {
    if (_from == address(0)) revert ZeroAddress();

    if (_walletExcluded[_from] || _walletExcluded[_to]) {
      _tax = 0;
    } else {
      require(_launch, "Trading not open");
      require(_amount <= maxTxAmount, "MaxTx Enabled at launch");
      // DEATHBLOCKS 3 BLOCKS AFTER LAUNCH
      if (block.number < _launchBlock + _buyValue + 2) {
        _tax = 99;
      } else {
        if (_from == uniswapV2Pair) {
          _tax = buyTax;
        } else if (_to == uniswapV2Pair) {
          uint256 _tokensToSwap = balanceOf(address(this));
          if (_tokensToSwap > MIN_SWAP) {
            if (_tokensToSwap > _ONE_PERCENT * 4) {
              _tokensToSwap = _ONE_PERCENT * 4;
            }
            _swapTokensForEth(_tokensToSwap);
          }
          _tax = sellTax;
        } else {
          _tax = 0;
        }
      }
    }
    _tokenTransfer(_from, _to, _amount);
  }

  function _swapTokensForEth(uint256 _tokenAmount) private {
    address[] memory _path = new address[](2);
    _path[0] = address(this);
    _path[1] = _uniswapV2Router.WETH();
    _approve(address(this), address(_uniswapV2Router), _tokenAmount);
    _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      _tokenAmount, 0, _path, _treasuryAddress, block.timestamp
    );
  }

  receive() external payable {}
}