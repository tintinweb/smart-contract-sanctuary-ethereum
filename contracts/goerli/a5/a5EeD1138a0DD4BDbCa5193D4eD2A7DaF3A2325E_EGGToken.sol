// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.13;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './interfaces/IEggShop.sol';
import './interfaces/IEGGToken.sol';
import './interfaces/IEGGTaxCalc.sol';
import './interfaces/IHenHouse.sol';
import './interfaces/IRandomizer.sol';
import './external/UniSwapV2/IUniswapV2Factory.sol';
import './external/UniSwapV2/IUniswapV2Router02.sol';



contract EGGToken is Context, IERC20, Ownable {
  using SafeMath for uint256;
  using Address for address;

  // Events
  event SwapAndLiquifyEnabledUpdated(bool enabled);
  event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
  event InitializedContract(address thisContract);

  struct TaxFeeStructure {
    address recipientAddress; // address to send fee to
    bool sendToContract; // This enables sending to above contract or not
    uint256 fee; // Percentage of tax fee
    uint256 previousFee; // Previous fee
    bool swapForEth; // if true then run swapTokensForEth
  }

  /**
   * 0 => Liquidity Fee Tax structure
   * 1 => Auto Burn Fee Tax structure
   * 2 => Dev Fee Tax structure
   * 3 => HenHouse Contract Fee Tax structure
   * 4 => DAO Fee Tax structure
   */

  TaxFeeStructure[] public taxFeeStructures;

  mapping(address => bool) private controllers; // address => allowedToCallFunctions

  mapping(address => bool) private _AddressExists;

  mapping(address => uint256) private _rOwned; // EGG balance of holders including the reflection
  mapping(address => uint256) private _tOwned; // EGG  balance of holders excluding the reflection
  mapping(address => mapping(address => uint256)) private _allowances;

  mapping(address => bool) private _isExcludedFromFee; // Address list to exculde the tax fee when EGG transfer
  mapping(address => bool) private _isExcluded; // Address list to exculde the reflection reward
  address[] private _excluded; // Address array excluded from reflection

  // References
  IRandomizer public randomizer; // Reference to Randomizer
  IEGGTaxCalc public eggTaxCalc; // Reference to EGGTaxCalc
  IUniswapV2Router02 public immutable uniswapV2Router; // Ref to Router

  uint256 private _tTotal = 4000000000 * 10**18; // Total EGG total amount

  uint256 private constant MAX = ~uint256(0);
  uint256 private _rTotal = (MAX - (MAX % _tTotal));

  uint256 private _tFeeTotal; // Total EGG reflection amount

  uint256 public totalMinted = 0; // Track the total minted amount

  uint256 public totalBurned = 0; // Track the total burned amount

  string private _name = 'TFG: EGG Token';
  string private _symbol = 'EGG';
  uint8 private _decimals = 18;

  // FIXME: All precentage inputs should be in the form of 10000 (100%) to 5000 (50%) etc. This allows for smaller percentage calcs
  uint256 public _reflectionFee = 1500; // Tax rate fee for the reflection when EGG transfer. 1500 = 15%
  uint256 private _previousReflectionFee = _reflectionFee;

  uint256 public _maxTxAmount = 4000000000 * 10**18; // Max amount avaialble for a single tx
  uint256 private numTokensSellToAddToLiquidity = 500000 * 10**18; // Minimum amount to add EGG to liquidity pool
  // HACK: Remove for dev
  // uint256 private numTokensSellToAddToLiquidity = 500000 * 10**6 * 10**9; // Minimum amount to add EGG to liquidity pool
  address public immutable uniswapV2Pair;

  address public liquidityTokenRecipient; // Recipient Address to get liquidityToken while swapping

  // Dev wallet
  uint256 public emissionPercent = 909; // Rate for the dev emission => 9.09%. 10000 = 100%, 500 = 5%
  address public emissionsAddress; // Dev emission address to receive 9.09% of mint $EGG

  bool inSwapAndLiquify;
  bool public swapAndLiquifyEnabled = false;

  /**
   * @dev Modifer to require the swap and liquify is alloed or not
   */

  modifier lockTheSwap() {
    inSwapAndLiquify = true;
    _;
    inSwapAndLiquify = false;
  }

  constructor(
    IRandomizer _randomizer,
    address sushiswapRouter,
    IEGGTaxCalc _eggTaxCalc
  ) {
    controllers[_msgSender()] = true;
    randomizer = _randomizer;
    eggTaxCalc = _eggTaxCalc;

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(sushiswapRouter);

    // Create a sushiswap pair for this new token
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

    // Set the rest of the contract variables
    uniswapV2Router = _uniswapV2Router;

    // Exclude owner and this contract from fee
    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;
    controllers[_msgSender()] = true;

    // Exclude routre from rewards
    excludeFromReward(sushiswapRouter);

    emit InitializedContract(address(this));
  }

  /**
   * @dev Modifer to require msg.sender to be a controller
   */
  modifier onlyController() {
    require(controllers[_msgSender()], 'Only controllers');
    _;
  }

  /**
   * @dev Modifer to require contract to be set before a transfer can happen
   */
  modifier requireContractsSet() {
    require(address(randomizer) != address(0), 'Contracts not set');
    _;
  }

  /**
   * ██ ███    ██ ████████
   * ██ ████   ██    ██
   * ██ ██ ██  ██    ██
   * ██ ██  ██ ██    ██
   * ██ ██   ████    ██
   * This section has internal only functions
   */

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) private {
    require(owner != address(0), 'From zero address');
    require(spender != address(0), 'To zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _burn(address _who, uint256 _value) internal {
    uint256 currentRate = _getRate();
    uint256 rAmount = _value.mul(currentRate);

    require(rAmount <= _rOwned[_who], 'Burn amount exceeds balance');
    _rOwned[_who] = _rOwned[_who].sub(rAmount);

    if (_isExcluded[_who]) {
      require(_value <= _tOwned[_who], 'Burn amount exceeds balance');
      _tOwned[_who] = _tOwned[_who].sub(_value);
    }
    emit Transfer(_who, address(0), _value);
  }

  /**
   * ██████  ██████  ██ ██    ██  █████  ████████ ███████
   * ██   ██ ██   ██ ██ ██    ██ ██   ██    ██    ██
   * ██████  ██████  ██ ██    ██ ███████    ██    █████
   * ██      ██   ██ ██  ██  ██  ██   ██    ██    ██
   * ██      ██   ██ ██   ████   ██   ██    ██    ███████
   * This section is for private fucntions
   */

  /**
   * @notice Calculate tax amount for the reflection
   * @param _amount EGG token tax amount
   */

  function calculateReflectionFee(uint256 _amount) private view returns (uint256) {

    uint256 fee = _amount.mul(_reflectionFee).div(10**4);

    return _amount.mul(_reflectionFee).div(10**4);
  }

  /**
   * @notice Calculate the dev emission fee when the tokens mint
   * @param _amount EGG token tax amount
   */

  function calculateDevEmission(uint256 _amount) private view returns (uint256) {
    return _amount.mul(emissionPercent).div(10**4);
  }

  /**
   * @notice Calculate the all taxFees (liquidity, autoburn, dev, henhouse, dao)
   * @param _amount EGG token tax amount
   */

  function calculateTaxFees(uint256 _amount) private view returns (uint256[] memory) {

    uint256[] memory _taxFees = new uint256[](taxFeeStructures.length);

    for (uint8 i = 0; i < taxFeeStructures.length; i++) {

      TaxFeeStructure memory taxFeeStructure = taxFeeStructures[i];

      _taxFees[i] = _amount.mul(taxFeeStructure.fee).div(10**2);
    }
    return _taxFees;
  }

  /**
   * @notice Transfer all tax fees to specific address regarding TaxFeeStructure data
   * @param _tAmounts Array of tax fees (0 => liquidity, 1 => autoburn, 2 => dev, 3 => henhouse, 4 => dao)
   */

  function distributeTax(uint256[] memory _tAmounts) private {

    for (uint8 i = 0; i < _tAmounts.length; i++) {

      if (_tAmounts[i] == 0) continue;
      TaxFeeStructure memory taxFeeStructrure = taxFeeStructures[i];
      address recipientAddress = taxFeeStructrure.recipientAddress;

      require(address(recipientAddress) != address(0), "Recipient address isn't set yet!");
      uint256 currentRate = _getRate();

      uint256 rAmount = _tAmounts[i].mul(currentRate);

      if (taxFeeStructrure.swapForEth && swapAndLiquifyEnabled) {
        swapTokensForEth(_tAmounts[i].div(2), recipientAddress);
        rAmount = rAmount.div(2);

        _tAmounts[i] = _tAmounts[i].div(2);

      }
      _rOwned[address(recipientAddress)] = _rOwned[address(recipientAddress)].add(rAmount);
      if (_isExcluded[address(recipientAddress)]) {
        _tOwned[address(recipientAddress)] = _tOwned[address(recipientAddress)].add(_tAmounts[i]);
      }
    }
  }

  struct TData {
    uint256 tAmount;
    uint256 tFee;
    uint256 currentRate;
    uint256[] taxFees;
  }

  /**
   * @notice Calculate each fee by the specified tax amount
   * @param tAmount Total tax amount to calculate the each fee
   */

  function _getValues(address sender, uint256 tAmount)
    private
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256[] memory
    )
  {


    (uint256 tTransferAmount, TData memory data) = _getTValues(sender, tAmount);
    data.tAmount = tAmount;

    data.currentRate = _getRate();

    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(data);



    return (rAmount, rTransferAmount, rFee, tTransferAmount, data.tFee, data.taxFees);
  }

  /**
   * @notice Calculate the amount of fee charged for each part
   * @param tAmount Total EGG token amount when the tokens transfer
   */

  function _getTValues(address sender, uint256 tAmount) private view returns (uint256, TData memory) {



    (uint256 taxRate, ) = eggTaxCalc.getTaxRate(sender);

    uint256 taxAmount = tAmount.mul(taxRate).div(10**4);

    uint256 tFee = calculateReflectionFee(taxAmount);

    uint256[] memory _taxFees = calculateTaxFees(taxAmount);
    uint256 tTransferAmount = tAmount.sub(taxAmount);

    return (tTransferAmount, TData(0, tFee, 0, _taxFees));
  }

  /**
   * @notice Calculate the reflection amounts of fee charged for each part
   * @param _data A struct that calculates the amount of each tax fee
   */

  function _getRValues(TData memory _data)
    private
    pure
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 rTaxFees = 0;
    for (uint8 i = 0; i < _data.taxFees.length; i++) {
      rTaxFees += _data.taxFees[i].mul(_data.currentRate);
    }
    uint256 rAmount = _data.tAmount.mul(_data.currentRate);
    uint256 rFee = _data.tFee.mul(_data.currentRate);
    uint256 rTransferAmount = rAmount.sub(rFee).sub(rTaxFees);

    return (rAmount, rTransferAmount, rFee);
  }

  /**
   * @notice Get the current reflection rate
   */

  function _getRate() public view returns (uint256) {
    (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();


    return rSupply.div(tSupply);
  }

  /**
   * @notice Get the current reflection supply
   */

  function _getCurrentSupply() private view returns (uint256, uint256) {
    uint256 rSupply = _rTotal;
    uint256 tSupply = _tTotal;
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
      rSupply = rSupply.sub(_rOwned[_excluded[i]]);
      tSupply = tSupply.sub(_tOwned[_excluded[i]]);
    }
    if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
    return (rSupply, tSupply);
  }

  /**
   * @notice Mint the EGG tokens to the receipt address
   * @param receipt Receipt address to mint the tokens
   * @param _amount The amount to mint the tokens
   */

  function _mint(address receipt, uint256 _amount) private {
    uint256 currentRate = _getRate();
    uint256 rAmount = _amount.mul(currentRate);

    _rOwned[receipt] = _rOwned[receipt].add(rAmount);

    if (_isExcluded[receipt]) _tOwned[receipt] = _tOwned[receipt].add(_amount);

    emit Transfer(address(this), receipt, _amount);
  }

  /**
   * @notice Burn the EGG tokens from the address
   * @param _from Receipt address to mint the tokens
   * @param _amount The amount of tokens to burn
   */

  function burn(address _from, uint256 _amount) public onlyController {
    _burn(_from, _amount);
    totalBurned = totalBurned.add(_amount);
  }

  /**
   * @notice Remove all fee rate when tax excluded
   */

  function removeAllFee() private {

    // FIXME: Prett sure the below line short circutes the taxFeeStructures being removed
    if (_reflectionFee == 0) return;

    _previousReflectionFee = _reflectionFee;
    _reflectionFee = 0;

    for (uint8 i = 0; i < taxFeeStructures.length; i++) {
      TaxFeeStructure memory taxFeeStructure = taxFeeStructures[i];
      taxFeeStructures[i] = TaxFeeStructure({
        recipientAddress: taxFeeStructure.recipientAddress,
        sendToContract: taxFeeStructure.sendToContract,
        fee: 0,
        previousFee: taxFeeStructure.fee,
        swapForEth: taxFeeStructure.swapForEth
      });
    }

  }

  /**
   * @notice Restore all fee rate
   */

  function restoreAllFee() private {

    _reflectionFee = _previousReflectionFee;
    for (uint8 i = 0; i < taxFeeStructures.length; i++) {
      TaxFeeStructure memory taxFeeStructure = taxFeeStructures[i];
      taxFeeStructures[i] = TaxFeeStructure({
        recipientAddress: taxFeeStructure.recipientAddress,
        sendToContract: taxFeeStructure.sendToContract,
        fee: taxFeeStructure.previousFee,
        previousFee: taxFeeStructure.previousFee,
        swapForEth: taxFeeStructure.swapForEth
      });
    }

  }

  // To recieve ETH from uniswapV2Router when swaping
  receive() external payable {}

  /**
   * @notice Add the reflection amount
   * rAmount means the token amount of the holders who will receive the reflection reward
   * tAmount means the amount that the exculde holders will receive from the reflection reward.
   * @param rFee Sub the fee form _rTotal to add the reflection
   * @param tFee Add the fee to add the reflection to _tFeeTotal
   */

  function _reflectFee(uint256 rFee, uint256 tFee) private {



    _rTotal = _rTotal.sub(rFee);

    _tFeeTotal = _tFeeTotal.add(tFee);


  }

  /**
   * @notice Transfer the EGG tokens from sender to receipt
   * @param _sender Sender address when the tokens transfer
   * @param _recipient Receipt address when the tokens transfer
   * @param _amount Amount of the tokens transfer
   */

  function _transfer(
    address _sender,
    address _recipient,
    uint256 _amount
  ) private requireContractsSet {




    require(_sender != address(0), 'From zero address');
    require(_recipient != address(0), 'To zero address');
    require(_amount > 0, 'Transfer amount must be greater than zero');

    if (_sender != owner() && _recipient != owner())
      require(_amount <= _maxTxAmount, 'Transfer amount exceeds maxTxAmount');

    // Is the token balance of this contract address over the min number of
    // tokens that we need to initiate a swap + liquidity lock?
    // also, don't get caught in a circular liquidity event.
    // also, don't swap & liquify if sender is uniswap pair.
    uint256 contractTokenBalance = _balanceOf(address(this));



    if (contractTokenBalance >= _maxTxAmount) {
      contractTokenBalance = _maxTxAmount;
    }

    bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;




    if (overMinTokenBalance && !inSwapAndLiquify && _sender != uniswapV2Pair && swapAndLiquifyEnabled) {
      contractTokenBalance = numTokensSellToAddToLiquidity;

      // Add liquidity
      swapAndLiquify(contractTokenBalance);
    }

    // Indicates if fee should be deducted from transfer
    bool takeFee = true;

    // If any account belongs to _isExcludedFromFee account then remove the fee
    if (_isExcludedFromFee[_sender] || _isExcludedFromFee[_recipient]) {
      takeFee = false;

    } else {
      // Transfer Tax is applied by 50% chance
      uint256 randomRate = randomizer.random().mod(10000);


      (, uint256 taxChance) = eggTaxCalc.getTaxRate(_sender);

      if (randomRate > taxChance) {
        takeFee = false;

      }

    }

    // Transfer amount, it will take tax, burn, liquidity fee
    _tokenTransfer(_sender, _recipient, _amount, takeFee);

  }

  /**
   * @notice Swap the half amount of contract balance to WETH and add to liquidity pool
   * @param _amount Amount of the EggToken to swap
   */

  function swapAndLiquify(uint256 _amount) private lockTheSwap {


    // Split the contract token balance into halves
    uint256 half = _amount.div(2);

    uint256 otherHalf = _amount.sub(half);


    // Capture the contract's current ETH balance.
    // This is so that we can capture exactly the amount of ETH that the
    // swap creates, and not make the liquidity event include any ETH that
    // has been manually sent to the contract
    uint256 initialBalance = address(this).balance;


    // Swap tokens for ETH
    swapTokensForEth(half, address(this)); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

    // Calculate how much ETH was just swapped into this contract
    uint256 newBalance = address(this).balance.sub(initialBalance);


    // Add liquidity to sushiswap
    addLiquidity(otherHalf, newBalance);

    emit SwapAndLiquify(half, newBalance, otherHalf);

  }

  /**
   * @notice Swap the EGG amount to WETH
   * @dev This is used to convert EGG to ETH. The ETH is added this contract, which then gets used by swapAndLiquify to add LP
   * @param tokenAmount EGG token amount to swap ETH
   *
   */

  function swapTokensForEth(uint256 tokenAmount, address recipient) private {
    // Generate the sushiswap pair path of token -> weth



    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokenAmount);


    // Make the swap
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // Accept any amount of ETH
      path,
      recipient,
      block.timestamp
    );

  }

  /**
   * @notice Swap the EGG amount to WETH
   * @param tokenAmount EGG token amount to add liquidity pool
   * @param ethAmount ETH amount to add liquidity pool
   */

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {


    // Approve token transfer to cover all possible scenarios
    _approve(address(this), address(uniswapV2Router), tokenAmount);


    // Add the liquidity
    uniswapV2Router.addLiquidityETH{ value: ethAmount }(
      address(this),
      tokenAmount,
      0, // Slippage is unavoidable
      0, // Slippage is unavoidable
      liquidityTokenRecipient,
      block.timestamp
    );

  }

  /**
   * @notice Swap the EGG amount to WETH
   * @param tokenAmount EGG token amount to add liquidity pool
   * @param _ethAmount ETH amount to add liquidity pool
   */

  function addLiquidityETH(uint256 tokenAmount, uint256 _ethAmount)
    external
    payable
    onlyController
    returns (
      uint256 _amountToken,
      uint256 _amountETH,
      uint256 _liquidity
    )
  {
    // Approve token transfer to cover all possible scenarios
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    _approve(_msgSender(), address(uniswapV2Router), tokenAmount);

    // Add the liquidity
    (uint256 amountToken, uint256 amountETH, uint256 liquidity) = uniswapV2Router.addLiquidityETH{ value: _ethAmount }(
      address(this),
      tokenAmount,
      0, // Slippage is unavoidable
      0, // Slippage is unavoidable
      liquidityTokenRecipient,
      block.timestamp
    );
    return (amountToken, amountETH, liquidity);
  }

  /**
   * @notice This method is responsible for taking all fee, if takeFee is true
   * @param sender Address of the sender
   * @param receipt Address of the receipt
   * @param amount Amount to be transferred
   * @param takeFee True = take fee, False = no fee
   */
  //
  function _tokenTransfer(
    address sender,
    address receipt,
    uint256 amount,
    bool takeFee
  ) private {

    if (!takeFee) removeAllFee();
    _transferStandard(sender, receipt, amount);
    if (!takeFee) restoreAllFee();

  }

  function _transferStandard(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee,
      uint256[] memory _tAmounts
    ) = _getValues(sender, tAmount);





    _rOwned[sender] = _rOwned[sender].sub(rAmount);

    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

    distributeTax(_tAmounts);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);

  }

  /**
   * @notice Transfer the EGG token to the dev wallet
   * @param tDev EGG token amount to send to the dev wallet
   */

  function _takeDev(uint256 tDev) private {
    require(address(emissionsAddress) != address(0), 'Dev emission address not set');
    uint256 currentRate = _getRate();
    uint256 rDev = tDev.mul(currentRate);
    _rOwned[emissionsAddress] = _rOwned[emissionsAddress].add(rDev);
    if (_isExcluded[emissionsAddress]) {
      _tOwned[emissionsAddress] = _tOwned[emissionsAddress].add(tDev);
    }
    // emit Transfer(address(this), emissionsAddress, _rOwned[emissionsAddress]);
  }

  /**
   * ███████ ██   ██ ████████
   * ██       ██ ██     ██
   * █████     ███      ██
   * ██       ██ ██     ██
   * ███████ ██   ██    ██
   * This section has external functions
   */

  /**
   * @notice Return balance of an address
   * @param account Address to get balance of
   * @return Address balance in wei
   */
  function balanceOf(address account) external view override returns (uint256) {
    return _balanceOf(account);
  }

  function _balanceOf(address account) internal view returns (uint256) {


    if (_isExcluded[account]) return _tOwned[account];

    return tokenFromReflection(_rOwned[account]);
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(subtractedValue, 'decreased allowance below zero')
    );
    return true;
  }

  /**
   * @notice Allows a user to give away tAmount of tokens as reflectins (Not excluded from fees).
   * @param tAmount Amount of EGG Tokens to deliver
   */

  function deliver(uint256 tAmount) public {
    address sender = _msgSender();
    require(!_isExcluded[sender], 'Excluded addresses cannot call');
    (uint256 rAmount, , , , , ) = _getValues(address(0), tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rTotal = _rTotal.sub(rAmount);
    _tFeeTotal = _tFeeTotal.add(tAmount);
  }

  /**
   * @notice Get the state excluded state of tax
   * @param account Address to get the excluded state of tax
   */

  function isExcludedFromFee(address account) public view returns (bool) {
    return _isExcludedFromFee[account];
  }

  /**
   * @notice Get the state excluded state of reward (reflection)
   * @param account Address to get the excluded state of reward (reflection)
   */

  function isExcludedFromReward(address account) public view returns (bool) {
    return _isExcluded[account];
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  /**
   * @notice If deductTransferFee is true, return the transfer amount of EGG Tokens exclude tax fee. if false, return reflection amount of tAmounts
   * @param tAmount Amount of EGG tokens to get the transfer or reflection amount
   * @param deductTransferFee If true, return the transfer amount exclude the tax fee. If false, return the reflection amount of tAmoutns
   */

  function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
    require(tAmount <= _tTotal, 'Amount must be less than supply');
    if (!deductTransferFee) {
      (uint256 rAmount, , , , , ) = _getValues(address(0), tAmount);
      return rAmount;
    } else {
      (, uint256 rTransferAmount, , , , ) = _getValues(address(0), tAmount);
      return rTransferAmount;
    }
  }

  /**
   * @notice Get the total reflection token amounts
   */

  function totalFees() public view returns (uint256) {
    return _tFeeTotal;
  }

  /**
   * @notice Get the reflection balance
   * @param rAmount Amount for calculating the reflection
   */

  function tokenFromReflection(uint256 rAmount) public view returns (uint256) {


    require(rAmount <= _rTotal, 'Amount must be less than total reflections');
    uint256 currentRate = _getRate();
    return rAmount.div(currentRate);
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
    return _tTotal;
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

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * Requirements:
   * - `sender` and `recipient` cannot be  the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``sender``'s tokens of at least
   * `amount`.
   */

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external virtual override returns (bool) {




    if (controllers[_msgSender()] || controllers[recipient]) {

      _approve(sender, _msgSender(), amount);
    }

    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, 'Transfer amount exceeds allowance'));

    return true;
  }

  /**
   *  ██████  ██████  ███    ██ ████████ ██████   ██████  ██      ██      ███████ ██████
   * ██      ██    ██ ████   ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██
   * ██      ██    ██ ██ ██  ██    ██    ██████  ██    ██ ██      ██      █████   ██████
   * ██      ██    ██ ██  ██ ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██
   *  ██████  ██████  ██   ████    ██    ██   ██  ██████  ███████ ███████ ███████ ██   ██
   * This section if for controllers (possibly Owner) only functions
   */

  /**
   * @notice Add the tax data into TaxFeeStructure
   * @param _recipientAddress Recipient address to get EGG tokens
   * @param _sendToContract If _recipientAddress is Deployed contract address, _sendToContract => true. If no, _sendToContract => false
   * @param _fee Tax Fee value of this TaxFeeStructure 10000 = 100%, 1010 = 10.10%
   * @param _previousFee Previous Tax Fee value of this TaxFeeStructure
   * @param _swapForEth If true then run swapTokensForEth
   */

  function addTaxFeeStructure(
    address _recipientAddress,
    bool _sendToContract,
    uint256 _fee,
    uint256 _previousFee,
    bool _swapForEth
  ) external onlyController {
    require(_recipientAddress != address(0), 'Recipient zero address.');
    taxFeeStructures.push(
      TaxFeeStructure({
        recipientAddress: _recipientAddress,
        sendToContract: _sendToContract,
        fee: _fee,
        previousFee: _previousFee,
        swapForEth: _swapForEth
      })
    );
  }

  /**
   * @notice Update the TaxFeeStructure regarding TaxFeeStructure id
   * @dev Only be callable by controllers
   * @param _recipientAddress Recipient address to get EGG tokens
   * @param _sendToContract If _recipientAddress is Deployed contract address, _sendToContract => true. If no, _sendToContract => false
   * @param _fee Tax Fee value of this TaxFeeStructure. 10000 = 100%, 1010 = 10.10%
   * @param _previousFee Previous Tax Fee value of this TaxFeeStructure
   * @param _swapForEth If true then run swapTokensForEth
   */

  function setTaxFeeStructure(
    uint16 id,
    address _recipientAddress,
    bool _sendToContract,
    uint256 _fee,
    uint256 _previousFee,
    bool _swapForEth
  ) external onlyController {
    require(id < taxFeeStructures.length, "TaxFeeStructrue doesn't exist");
    require(_recipientAddress != address(0), 'Recipient zero address');
    taxFeeStructures[id] = TaxFeeStructure(_recipientAddress, _sendToContract, _fee, _previousFee, _swapForEth);
  }

  /**
   @notice Get the Tax Fee Structure Info by structure id
   @param id Structure id to get the tax fee structure info
   */

  function getTaxFeeStructure(uint8 id) public view returns (TaxFeeStructure memory) {
    require(id < taxFeeStructures.length, "TaxFeeStructure data isn't exist");
    return taxFeeStructures[id];
  }

  /**
   * @notice Exclude the account from the tax fee
   * @dev Only be callable by controllers
   * @param account Address to exclude the tax fee
   */

  function excludeFromFee(address account) public onlyController {
    _isExcludedFromFee[account] = true;
  }

  /**
   * @notice Include the account from the tax fee
   * @dev Only be callable by controllers
   * @param account Address to include the tax fee
   */

  function includeInFee(address account) public onlyController {
    _isExcludedFromFee[account] = false;
  }

  /**
   * @notice Set the rate for the reflection
   * @dev Only be callable by controllers
   * @param reflectionFee Tax rate for the reflection
   */

  function setReflectionFee(uint256 reflectionFee) external onlyController {
    _reflectionFee = reflectionFee;
  }

  /**
   * @notice Set the rate of tokens that can be transferred at one time
   * @dev Only be callable by controllers
   * @param maxTxPercent Rate of tokens that can be transferred at one time
   */

  function setMaxTx(uint256 maxTxPercent) external onlyController {
    _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
  }

  /**
   * @notice Set enable state of the swapAndLqiuidityPool
   * @dev Only be callable by controllers
   * @param _enabled Enable state of the swapAndLiquidityPool
   */

  function setSwapAndLiquifyEnabled(bool _enabled) external onlyController {
    swapAndLiquifyEnabled = _enabled;
    emit SwapAndLiquifyEnabledUpdated(_enabled);
  }

  /**
   * @notice Add the account to the rewardExculed
   * @dev Only be callable by controllers
   * @param account Address to excluded from the reward
   */

  function excludeFromReward(address account) public onlyController {
    // Uniswap rounder should  be exluded from reward or and not excluded from fee
    require(!_isExcluded[account], 'Account already excluded');
    if (_rOwned[account] > 0) {
      _tOwned[account] = tokenFromReflection(_rOwned[account]);
    }
    _isExcluded[account] = true;
    _excluded.push(account);
  }

  /**
   * @notice Remove the account from the rewardExculed
   * @dev Only be callable by controllers
   * @param account Address to include from the reward
   */

  function includeInReward(address account) external onlyController {
    require(_isExcluded[account], 'Account already included');
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_excluded[i] == account) {
        _excluded[i] = _excluded[_excluded.length - 1];
        _tOwned[account] = 0;
        _isExcluded[account] = false;
        _excluded.pop();
        break;
      }
    }
  }

  /**
   * @notice Set the dev emission rate to mint the EGG token to the dev wallet
   * @dev Only be callable by controllers
   * @param devEmission Rate of dev emission // 909 = 9.09%
   */

  function setDevEmission(uint256 devEmission) external onlyController {
    emissionPercent = devEmission;
  }

  /**
   * @notice Set the dev emission address to send the emission tokens when EGG Tokens mint
   * @dev Only be callable by controllers
   * @param _emissionAddress Emission address to get the emission EGG Tokens when EGG tokens mint
   */

  function setDevEmissionAddress(address _emissionAddress) external onlyController {
    emissionsAddress = _emissionAddress;
  }

  /**
   * @notice Set the liquidity Token Recipient Address
   * @dev Only be callable by controllers
   * @param _recipient Recipient Address
   */

  function setLiquidityTokenRecipient(address _recipient) public onlyController {
    liquidityTokenRecipient = _recipient;
  }

  /**
   * @notice Mints EGG to a recipient.
   * @param to the recipient of the EGG
   * @param amount Amount of EGG to mint
   */

  function mint(address to, uint256 amount) external onlyController {
    uint256 tDevEmissionFee = calculateDevEmission(amount);
    _mint(to, amount);

    _takeDev(tDevEmissionFee);

    totalMinted = totalMinted.add(amount);
  }

  /**
   * @notice Remove the TaxFeeStructure regarding TaxFeeStructure id
   * @dev Only be callable by controllers
   * @param id TaxFeeStructure id to remove the tax fee data from TaxFeeStructure
   */

  function removeTaxFeeStructure(uint16 id) external onlyController {
    require(id < taxFeeStructures.length, "TaxFeeStructrue doesn't exist");
    TaxFeeStructure memory lastTaxFeeStructure = taxFeeStructures[taxFeeStructures.length - 1];
    taxFeeStructures[id] = lastTaxFeeStructure; //  Shuffle last taxFeeStructures to current position
    taxFeeStructures.pop();
  }

  /**
   *   ██████  ██     ██ ███    ██ ███████ ██████
   *  ██    ██ ██     ██ ████   ██ ██      ██   ██
   *  ██    ██ ██  █  ██ ██ ██  ██ █████   ██████
   *  ██    ██ ██ ███ ██ ██  ██ ██ ██      ██   ██
   *   ██████   ███ ███  ██   ████ ███████ ██   ██
   * This section will have all the internals set to onlyOwner
   */

  /**
   * @notice Internal call to enable an address to call controller only functions
   * @param _address the address to enable
   */
  function _addController(address _address) internal {
    controllers[_address] = true;
  }

  /**
   * @notice enables an address to call controller only functions
   * @dev Only callable by the owner or existing controller
   * @param _address the address to enable
   */
  function addController(address _address) external onlyController {
    _addController(_address);
  }

  /**
   * @notice enables multiple addresses to call controller only functions
   * @dev Only callable by the owner or existing controller
   * @param _addresses array of the address to enable
   */
  function addManyControllers(address[] memory _addresses) external onlyController {
    for (uint256 i = 0; i < _addresses.length; i++) {
      _addController(_addresses[i]);
    }
  }

  /**
   * @notice removes an address from controller list and ability to call controller only functions
   * @dev Only callable by the owner or existing controller
   * @param _address the address to disable
   */
  function removeController(address _address) external onlyController {
    controllers[_address] = false;
  }
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.13;

interface IEGGToken {
  function balanceOf(address account) external view returns (uint256);

  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  function addLiquidityETH(uint256 tokenAmount, uint256 ethAmount)
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

pragma solidity ^0.8.13;

interface IEggShop is IERC1155 {
  struct TypeInfo {
    uint16 mints;
    uint16 burns;
    uint16 maxSupply;
    uint256 eggMintAmt;
    uint256 eggBurnAmt;
  }

  struct DetailedTypeInfo {
    uint16 mints;
    uint16 burns;
    uint16 maxSupply;
    uint256 eggMintAmt;
    uint256 eggBurnAmt;
    string name;
  }

  function mint(
    uint256 typeId,
    uint16 qty,
    address recipient,
    uint256 eggAmt
  ) external;

  function burn(
    uint256 typeId,
    uint16 qty,
    address burnFrom,
    uint256 eggAmt
  ) external;

  // function balanceOf(address account, uint256 id) external returns (uint256);

  function getInfoForType(uint256 typeId) external view returns (TypeInfo memory);

  function getInfoForTypeName(uint256 typeId) external view returns (DetailedTypeInfo memory);

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external;
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.13;

interface IRandomizer {
  function random() external view returns (uint256);

  function randomToken(uint256 _tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.13;

interface IHenHouse {
  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    address owner;
    uint80 eggPerRank; // This is the value of EggPerRank (Coyote/Rooster)
    uint80 rescueEggPerRank; // Value per rank of rescued $EGG
    uint256 oneOffEgg; // One off per staker
    uint256 stakedTimestamp;
    uint256 unstakeTimestamp;
  }

  struct HenHouseInfo {
    uint256 numHensStaked; // Track staked hens
    uint256 totalEGGEarnedByHen; // Amount of $EGG earned so far
    uint256 lastClaimTimestampByHen; // The last time $EGG was claimed
  }

  struct DenInfo {
    uint256 numCoyotesStaked;
    uint256 totalCoyoteRankStaked;
    uint256 eggPerCoyoteRank; // Amount of tax $EGG due per Wily rank point staked
  }

  struct GuardHouseInfo {
    uint256 numRoostersStaked;
    uint256 totalRoosterRankStaked;
    uint256 totalEGGEarnedByRooster;
    uint256 lastClaimTimestampByRooster;
    uint256 eggPerRoosterRank; // Amount of dialy $EGG due per Guard rank point staked
    uint256 rescueEggPerRank; // Amunt of rescued $EGG due per Guard rank staked
  }

  function addManyToHenHouse(address account, uint16[] calldata tokenIds) external;

  function addGenericEggPool(uint256 _amount) external;

  function addRescuedEggPool(uint256 _amount) external;

  function canUnstake(uint16 tokenId) external view returns (bool);

  function claimManyFromHenHouseAndDen(uint16[] calldata tokenIds, bool unstake) external;

  function getDenInfo() external view returns (DenInfo memory);

  function getGuardHouseInfo() external view returns (GuardHouseInfo memory);

  function getHenHouseInfo() external view returns (HenHouseInfo memory);

  function getStakeInfo(uint16 tokenId) external view returns (Stake memory);

  function randomCoyoteOwner(uint256 seed) external view returns (address);

  function randomRoosterOwner(uint256 seed) external view returns (address);

  function rescue(uint16[] calldata tokenIds) external;
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for EGGTaxCalc

/*
&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day
*/

pragma solidity ^0.8.13;

interface IEGGTaxCalc {
  function getTaxRate(address sender) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function migrator() external view returns (address);

  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB) external returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;

  function setMigrator(address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}