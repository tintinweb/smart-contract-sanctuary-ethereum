// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC20.sol";
import "./Ownable.sol";

import "./IDEXRouter.sol";

contract Token is ERC20, Ownable {
  uint256 private constant _TOTAL_SUPPLY = 1_000_000_000 ether;
  uint256 public constant MAX_HOLD_PER_WALLET = (_TOTAL_SUPPLY * 3) / 100; // 3%

  uint256 public minFeesToCollect = _TOTAL_SUPPLY / 10000; // 0.01%
  bool private _inSwap;
  mapping(address => uint256) private _balances;
  mapping(address => bool) private _isFeeExempt;
  mapping(address => bool) private _noCheckMaxHold;
  bool private _autoCollectFees;

  address public treasury;
  IDEXRouter public router;

  address public ecosystemWallet;
  // uniswap pair address of WGMI - WETH pool
  address public pair;

  uint256 public tradeFee = 8;
  uint256 public feeDenominator = 100;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    address _treasury,
    address _ecosystemWallet,
    address _router
  ) ERC20(_tokenName, _tokenSymbol) {
    address deployer = msg.sender;

    ecosystemWallet = _ecosystemWallet;
    treasury = _treasury;
    router = IDEXRouter(_router);

    _autoCollectFees = true;
    _noCheckMaxHold[address(this)] = true;
    _noCheckMaxHold[ecosystemWallet] = true;
    _noCheckMaxHold[deployer] = true;
    _noCheckMaxHold[treasury] = true;

    _isFeeExempt[address(this)] = true;
    _isFeeExempt[ecosystemWallet] = true;
    _isFeeExempt[deployer] = true;
    _isFeeExempt[treasury] = true;

    uint256 amountForEcosystemWallet = _TOTAL_SUPPLY / 4; // 25% of totalSupply
    uint256 amountForConvertLegacyWGMIContract = _TOTAL_SUPPLY - amountForEcosystemWallet; // 75 % of total supply

    _mint(ecosystemWallet, amountForEcosystemWallet);
    _mint(deployer, amountForConvertLegacyWGMIContract);
  }

  modifier swapping() {
    _inSwap = true;
    _;
    _inSwap = false;
  }

  function setMinFeesToCollect(uint256 amount) external onlyOwner {
    minFeesToCollect = amount;
  }

  function setAutoCollectFees(bool flag) external onlyOwner {
    _autoCollectFees = flag;
  }

  function collectFees() external onlyOwner {
    require(_shouldCollectFees(), "NO_FEES_TO_COLLECT");
    _collectFeesInETHAndSendToTreasury();
  }

  function setFeeExempt(address _address, bool _flag) external onlyOwner {
    _isFeeExempt[_address] = _flag;
  }

  function setNoCheckMaxHold(address address_, bool flag) external onlyOwner {
    _noCheckMaxHold[address_] = flag;
  }

  function setTradeFee(uint256 fee, uint256 denominator) external onlyOwner {
    tradeFee = fee;
    feeDenominator = denominator;
  }

  function setRouter(IDEXRouter _router) external onlyOwner {
    router = _router;
  }

  function setPair(address _pair) external onlyOwner {
    pair = _pair;
  }

  function _shouldTakeFee(address from, address to) internal view returns (bool) {
    return (pair == from || pair == to) && !_isFeeExempt[from];
  }

  function transfer(address to, uint256 amount) public virtual override returns (bool) {
    address owner = _msgSender();
    _transfer(owner, to, amount);
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

  function _mint(address account, uint256 amount) internal virtual override {
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);
  }

  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    require(amount > 0, "INVALID_AMOUNT");
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");

    uint256 fromBalance = _balances[from];
    require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

    if (!_noCheckMaxHold[to]) {
      require(balanceOf(to) + amount <= MAX_HOLD_PER_WALLET, "EXCEEDS_MAX_AMOUNT_PER_WALLET");
    }

    // only check and execute funding treasury for sell txs
    if (to == pair && _autoCollectFees && _shouldCollectFees()) {
      _collectFeesInETHAndSendToTreasury();
    }

    unchecked {
      _balances[from] = fromBalance - amount;
    }

    uint256 receivedAmount = _shouldTakeFee(from, to) ? _takeFee(amount) : amount;
    _balances[to] += receivedAmount;
    emit Transfer(from, to, receivedAmount);
  }

  function _takeFee(uint256 amount) internal returns (uint256) {
    uint256 feeAmount = (amount * tradeFee) / feeDenominator;
    _balances[address(this)] += feeAmount;
    uint256 remain = amount - feeAmount;
    return remain;
  }

  function _shouldCollectFees() internal view returns (bool) {
    return !_inSwap && balanceOf(address(this)) >= minFeesToCollect;
  }

  function _collectFeesInETHAndSendToTreasury() internal swapping {
    uint256 amountToSwap = balanceOf(address(this));

    if(allowance(address(this), address(router)) < amountToSwap) {
      _approve(address(this), address(router), type(uint256).max);
    }

    uint256 balanceBefore = address(this).balance;
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = router.WETH();
    router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountToSwap, 0, path, address(this), block.timestamp);

    uint256 amountETHToTreasury = address(this).balance - balanceBefore;
    payable(treasury).transfer(amountETHToTreasury);
  }

  function totalSupply() public pure override returns (uint256) {
    return _TOTAL_SUPPLY;
  }

  function withdraw() public onlyOwner {
      payable(msg.sender).transfer(address(this).balance);
  }

  function withdrawErc20(IERC20 _token) public onlyOwner {
      _token.transfer(msg.sender, _token.balanceOf(address(this)));
  }

  receive() external payable {}
}