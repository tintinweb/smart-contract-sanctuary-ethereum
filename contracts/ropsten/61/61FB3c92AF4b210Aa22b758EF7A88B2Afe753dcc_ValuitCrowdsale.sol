// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import './crowdsale/Crowdsale.sol';
import './crowdsale/TimedCrowdsale.sol';
import './crowdsale/MintedCrowdsale.sol';
import './crowdsale/WhitelistedCrowdsale.sol';
import './crowdsale/IndividuallyCappedCrowdsale.sol';
import './tokens/PausableToken.sol';
import './tokens/MintableToken.sol';
import './libraries/SafeMath.sol';
import './Ownable.sol';

contract ValuitCrowdsale is Crowdsale, TimedCrowdsale, MintedCrowdsale, WhitelistedCrowdsale, IndividuallyCappedCrowdsale, Ownable {
  using SafeMath for uint;

  // Crowdsale Stages
  enum CrowdsaleStage { PreICO, PostICO }
  // Investment Payment Types
  enum PaymentTypes { Wei, ERC20Token, FiatCurrency}

  // Default to presale stage
  CrowdsaleStage public stage = CrowdsaleStage.PreICO;

  // Token Distribution
  uint public immutable tokenSalePercentage = 80;
  uint public immutable foundersPercentage = 10;
  uint public immutable partnersPercentage = 10;

  // Token reserve funds
  address public foundersAddress;
  address public partnersAddress;

  struct Contributions {
    PaymentTypes types;
    string symbol;
    uint amount;
  }

  constructor(
    uint _rate,
    address _wallet,
    address _token,
    address _usdtToken,
    address _kycAddress,
    uint _openingTime,
    uint _closingTime,
    address _foundersAddress,
    address _partnersAddress
  )
    Crowdsale(_kycAddress, _rate, _wallet, _token, _usdtToken, 'USD')
    TimedCrowdsale(_openingTime, _closingTime) {

    require(keccak256(abi.encodePacked(IERC20(_usdtToken).symbol())) == keccak256(abi.encodePacked("USDT")));
    foundersAddress = _foundersAddress;
    partnersAddress = _partnersAddress;
  }

  /**
   * @dev low level token purchase through supported ERC20 Token transfer
   * @param _beneficiary Address performing the token purchase
   * @param _erc20Token ERC20 Token Address used to token purchase
   * @param _amount amount of ERC20 Token transferred
   * @param _weiAmount equivalent amount of wei transferred
   */
  function buyTokensByAdmin(address _beneficiary, address _erc20Token, string calldata _currency, uint _amount, uint _weiAmount) external onlyOwner {
    require(bytes(_currency).length > 0 || _erc20Token != address(0), 'Currency/ERC20 must present');
    if(_erc20Token != address(0)) {
      buyTokensByERC20(_beneficiary, _erc20Token, _amount, _weiAmount);
    } else if(bytes(_currency).length > 0) {
      buyTokensByCurrency(_beneficiary, _currency, _amount, _weiAmount);
    }
  }

  function buyTokensByERC20(address _beneficiary, address _erc20Token, uint _amount, uint _weiAmount) internal {
    require(supportedERC20Tokens[_erc20Token], 'ERC20 token not Supported');
    //beneficiary must approve amount to be transferred to wallet address.
    IERC20(_erc20Token).transferFrom(_beneficiary, wallet, _amount);
    erc20TokenRaised[_erc20Token] = erc20TokenRaised[_erc20Token].add(_amount);
    _buyTokens(_beneficiary, _weiAmount, false);
    _updateERC20PurchasingState(_beneficiary, _erc20Token, _amount);
  }
  /**
   * @dev low level token purchase through supported Fiat Currency transfer
   * @param _beneficiary Address performing the token purchase
   * @param _currency  letter Symbol of the Fiat Currency
   * @param _amount amount of fiat currency transferred
   * @param _weiAmount equivalent amount of wei transferred
   */
  function buyTokensByCurrency(address _beneficiary, string calldata _currency, uint _amount, uint _weiAmount) internal {
    require(supportedCurrencies[_currency], 'Fiat Currency not Supported');
    fiatCurrencyRaised[_currency] = fiatCurrencyRaised[_currency].add(_amount);
    _buyTokens(_beneficiary, _weiAmount, false);
    _updateCurrencyPurchasingState(_beneficiary, _currency, _amount);
  }
  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract's finalization function.
   */
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }
  /**
   * @dev enables token transfers, called when owner calls finalize()
  */
  function finalization() internal override {
    require(block.timestamp >= closingTime, 'Not yet time for Finalization');
    setCrowdsaleStage(uint(CrowdsaleStage.PostICO));
    uint _alreadyMinted = MintableToken(token).totalSupply();

    uint _newTotalSupply = _alreadyMinted.div(tokenSalePercentage).mul(100);
    MintableToken(token).mint(foundersAddress, _newTotalSupply.mul(foundersPercentage).div(100));
    MintableToken(token).mint(partnersAddress, _newTotalSupply.mul(partnersPercentage).div(100));

    PausableToken(token).unpause();
    PausableToken(token).transferOwnership(wallet);
  }

  function isPreICO() public view returns (bool){
    if(stage == CrowdsaleStage.PreICO) {
      return true;
    }
    return false;
  }
  function isPostICO() public view returns (bool){
    if(stage == CrowdsaleStage.PostICO) {
      return true;
    }
    return false;
  }
  /**
  * @dev Allows admin to update the crowdsale stage
  * @param _stage Crowdsale stage
  */
  function setCrowdsaleStage(uint _stage) public onlyOwner {
    if(uint(CrowdsaleStage.PreICO) == _stage) {
      stage = CrowdsaleStage.PreICO;
    } else if (uint(CrowdsaleStage.PostICO) == _stage) {
      stage = CrowdsaleStage.PostICO;
    }
  }
  /**
  * @dev Allows admin/owner to update the crowdsale fund address
  * @param _newWallet Crowdsale new wallet address
  */
  function setFundAddress(address _newWallet) external onlyOwner {
    wallet = _newWallet;
  }
  /**
  * @dev Allows admin/owner to update the crowdsale closing time
  * @param _closingTime Crowdsale closing time
  */
  function setClosingTime(uint _closingTime) external onlyOwner {
    require(_closingTime > 0 && _closingTime >= openingTime);
    closingTime = _closingTime;
  }
  /**
  * @dev Register any new ERC20 Token
  * @param _symbol Symbol of the ERC20 Token
  * @param _erc20Token address of the ERC20 Token
  */
  function registerERC20Token(string calldata _symbol, address _erc20Token) external onlyOwner {
    require(_erc20Token != address(0));
    require(keccak256(abi.encodePacked(IERC20(_erc20Token).symbol())) == keccak256(abi.encodePacked(_symbol)));

    supportedERC20Tokens[_erc20Token] = true;
  }
 /**
  * @dev Deregister ERC20 Token
  * @param _erc20Token address of the ERC20 Token
  */
  function deRegisterERC20Token(address _erc20Token) external onlyOwner {
    require(_erc20Token != address(0));
    supportedERC20Tokens[_erc20Token] = false;
  }
  /**
  * @dev Register any new Fiat Currency
  * @param _currency 3 letter Symbol of the Fiat Currency
  */
  function registerFiatCurrency(string calldata _currency) external onlyOwner {
    require(bytes(_currency).length > 0);
    supportedCurrencies[_currency] = true;
  }
  /**
  * @dev Deregister Fiat Currency
  * @param _currency 3 letter Symbol of the Fiat Currency
  */
  function deRegisterFiatCurrency(string calldata _currency) external onlyOwner {
    require(bytes(_currency).length > 0);
    supportedCurrencies[_currency] = false;
  }
  /**
   * @dev Sets all user's minimum & maximum contribution.
   * @param _minCap min Wei limit for individual contribution
   */
  function setUserCap(uint _minCap) external onlyOwner {
    MinCap = _minCap;
    MaxCap = ~uint256(0);
  }
  /**
   * @dev Sets all user's minimum & maximum contribution.
   * @param _minCap min Wei limit for individual contribution
   * @param _maxCap max Wei limit for individual contribution
   */
  function setUserCap(uint _minCap, uint _maxCap) external onlyOwner {
    MinCap = _minCap;
    MaxCap = _maxCap;
  }
  /**
   * @dev Sets a specific user's maximum contribution.
   * @param _beneficiary IPFS Hash of the user to be capped
   * @param _minCap min Wei limit for individual contribution
   */
  function setUserCap(bytes32 _beneficiary, uint _minCap) public onlyOwner {
    if(_minCap == 0) _minCap = MinCap;
    minCaps[_beneficiary] = _minCap;
    maxCaps[_beneficiary] = ~uint256(0);
  }
  /**
   * @dev Sets a specific user's maximum contribution.
   * @param _beneficiary IPFS Hash of the user to be capped
   * @param _minCap min Wei limit for individual contribution
   * @param _maxCap max Wei limit for individual contribution
   */
  function setUserCap(bytes32 _beneficiary, uint _minCap, uint _maxCap) public onlyOwner {
    if(_minCap == 0) _minCap = MinCap;
    if(_maxCap == 0) _minCap = MaxCap;
    minCaps[_beneficiary] = _minCap;
    maxCaps[_beneficiary] = _maxCap;
  }
  /**
   * @dev Sets a specific user's maximum contribution.
   * @param _beneficiary address of user wallet
   * @param _minCap min Wei limit for individual contribution
   */
  function setUserCap(address _beneficiary, uint _minCap) external onlyOwner {
    bytes32 userId = IKYC(kycContract).getWalletOwner(_beneficiary);
    setUserCap(userId, _minCap, ~uint256(0));
  }
  /**
   * @dev Sets a specific user's maximum contribution.
   * @param _beneficiary address of user wallet
   * @param _minCap min Wei limit for individual contribution
   * @param _maxCap max Wei limit for individual contribution
   */
  function setUserCap(address _beneficiary, uint _minCap, uint _maxCap) external onlyOwner {
    bytes32 userId = IKYC(kycContract).getWalletOwner(_beneficiary);
    setUserCap(userId, _minCap, _maxCap);
  }
  /**
   * @dev Sets a group of users' maximum contribution.
   * @param _beneficiaries List of addresses to be capped
   * @param _minCap min Wei limit for individual contribution
   */
  function setGroupCap(address[] memory _beneficiaries, uint _minCap) external onlyOwner {
    bytes32 userId;
    for (uint i = 0; i < _beneficiaries.length; i++) {
      userId = IKYC(kycContract).getWalletOwner(_beneficiaries[i]);
      setUserCap(userId, _minCap, ~uint256(0));
    }
  }
  /**
   * @dev Sets a group of users' maximum contribution.
   * @param _beneficiaries List of addresses to be capped
   * @param _minCap min Wei limit for individual contribution
   * @param _maxCap max Wei limit for individual contribution
   */
  function setGroupCap(address[] memory _beneficiaries, uint _minCap, uint _maxCap) external onlyOwner {
    bytes32 userId;
    for (uint i = 0; i < _beneficiaries.length; i++) {
      userId = IKYC(kycContract).getWalletOwner(_beneficiaries[i]);
      setUserCap(userId, _minCap, _maxCap);
    }
  }
  /**
   * @dev Sets a group of users' maximum contribution.
   * @param _beneficiaries List of User IPFS hashes to be capped
   * @param _minCap min Wei limit for individual contribution
   */
  function setGroupCap(bytes32[] memory _beneficiaries, uint _minCap) external onlyOwner {
    for (uint i = 0; i < _beneficiaries.length; i++) {
      setUserCap(_beneficiaries[i], _minCap, ~uint256(0));
    }
  }
  /**
   * @dev Sets a group of users' maximum contribution.
   * @param _beneficiaries List of User IPFS hashes to be capped
   * @param _minCap min Wei limit for individual contribution
   * @param _maxCap max Wei limit for individual contribution
   */
  function setGroupCap(bytes32[] memory _beneficiaries, uint _minCap, uint _maxCap) external onlyOwner {
    for (uint i = 0; i < _beneficiaries.length; i++) {
      setUserCap(_beneficiaries[i], _minCap, _maxCap);
    }
  }
  /**
   * @dev getter method to get Users equivalent wei contributions
   * @param _beneficiary Token purchaser wallet address
   */
  function getEffectiveUserContributionsInWei(address _beneficiary) external view returns (uint){
    require(_beneficiary != address(0));
    require(msg.sender == _beneficiary || msg.sender == owner(), 'Only beneficiary/Owner is allowed');
    bytes32 userId = IKYC(kycContract).getWalletOwner(_beneficiary);
  
    return contributions[userId];
  }
  /**
   * @dev getter method to get Users total contributions in Wei
   * @param _beneficiary Token purchaser wallet address
   */
  function getUserContributionsByWei(address _beneficiary) public view returns (uint){
    require(_beneficiary != address(0));
    require(msg.sender == _beneficiary || msg.sender == owner(), 'Only beneficiary/Owner is allowed');
    bytes32 userId = IKYC(kycContract).getWalletOwner(_beneficiary);
  
    return (weiContributions[userId]);
  }
  /**
   * @dev getter method to get Users total contributions in ERC20 Tokens
   * @param _beneficiary Token purchaser wallet address
   * @param _tokenAddresses ERC20 Token addresses
   */
  function getUserContributionsByERC20(address _beneficiary, address[] calldata _tokenAddresses) public view returns (Contributions[] memory){
    require(_beneficiary != address(0));
    require(msg.sender == _beneficiary || msg.sender == owner(), 'Only beneficiary/Owner is allowed');
    bytes32 userId = IKYC(kycContract).getWalletOwner(_beneficiary);
    Contributions[] memory contributions = new Contributions[](_tokenAddresses.length);
    string memory _tokenSymbol;
    Contributions memory _contribution;
    for(uint16 i = 0; i< _tokenAddresses.length; i++) {
      _tokenSymbol = IERC20(_tokenAddresses[i]).symbol();
      _contribution = Contributions({
        types: PaymentTypes.ERC20Token,
        symbol: _tokenSymbol,
        amount: erc20Contributions[userId][_tokenAddresses[i]]
      });
      contributions[i] = _contribution;
    }
    return contributions;
  }
  /**
   * @dev getter method to get Users total contributions in Fiat Currencies
   * @param _beneficiary Token purchaser wallet address
   * @param _currencies Fiat Currency Symbols like USD, EUR, INR etc
   */
  function getUserContributionsByCurrency(address _beneficiary, string[] calldata _currencies) public view returns (Contributions[] memory){
    require(_beneficiary != address(0));
    require(msg.sender == _beneficiary || msg.sender == owner(), 'Only beneficiary/Owner is allowed');
    bytes32 userId = IKYC(kycContract).getWalletOwner(_beneficiary);
    Contributions[] memory contributions = new Contributions[](_currencies.length);
    Contributions memory _contribution;
    for(uint16 i = 0; i< _currencies.length; i++) {
      _contribution = Contributions({
        types: PaymentTypes.FiatCurrency,
        symbol: _currencies[i],
        amount: fiatCurrencyContributions[userId][_currencies[i]]
      });
      contributions[i] = _contribution;
    }
    return contributions;
  }
  /**
   * @dev getter method to get Users total contributions in all types of payment methods
   * @param _beneficiary Token purchaser wallet address
   * @param _tokenAddresses ERC20 Token addresses
   * @param _currencies Fiat Currency Symbols like USD, EUR, INR etc
   */
  function getUserContributionsByAllMethods(address _beneficiary, address[] calldata _tokenAddresses, 
            string[] calldata _currencies) external view returns (uint, Contributions[] memory, Contributions[] memory){
    uint weiContributions = getUserContributionsByWei(_beneficiary);
    Contributions[] memory erc20Contributions = getUserContributionsByERC20(_beneficiary, _tokenAddresses);
    Contributions[] memory currencyContributions = getUserContributionsByCurrency(_beneficiary, _currencies);
    return (weiContributions, erc20Contributions, currencyContributions);
  }
  /**
   * @dev Overrides and calls parent behavior requiring to be within contributing period
   * @param _beneficiary Token purchaser wallet address
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address _beneficiary, uint _weiAmount) internal override(TimedCrowdsale, WhitelistedCrowdsale, IndividuallyCappedCrowdsale, Crowdsale) {
    TimedCrowdsale._preValidatePurchase(_beneficiary, _weiAmount);
    WhitelistedCrowdsale._preValidatePurchase(_beneficiary, _weiAmount);
    IndividuallyCappedCrowdsale._preValidatePurchase(_beneficiary, _weiAmount);
  }
  /**
   * @dev Overrides and calls delivery by minting tokens upon purchase.
   * @param _beneficiary Token purchaser wallet address
   * @param _tokenAmount Number of tokens to be minted
   */
  function _deliverTokens(address _beneficiary, uint _tokenAmount) internal override(MintedCrowdsale, Crowdsale) {
    MintedCrowdsale._deliverTokens(_beneficiary, _tokenAmount);
  }
  /**
   * @dev Extend parent behavior to update effective user contributions in wei
   * @param _beneficiary Token purchaser wallet address
   * @param _weiAmount Amount of wei contributed
   */
  function _updatePurchasingState(address _beneficiary, uint _weiAmount) internal override(IndividuallyCappedCrowdsale, Crowdsale) {
    IndividuallyCappedCrowdsale._updatePurchasingState(_beneficiary, _weiAmount);
  }
  /**
   * @dev Extend parent behavior to update only Wei contributions
   * @param _beneficiary Token purchaser wallet address
   * @param _weiAmount Amount of wei contributed
   */
  function _updateWeiPurchasingState(address _beneficiary, uint _weiAmount) internal override(IndividuallyCappedCrowdsale, Crowdsale) {
    IndividuallyCappedCrowdsale._updateWeiPurchasingState(_beneficiary, _weiAmount);
  }
  /**
   * @dev Extend parent behavior to update only ERC20 contributions
   * @param _beneficiary Token purchaser wallet address
   * @param _erc20Token ERC20 Token Address
   * @param _amount Amount of wei contributed
   */
  function _updateERC20PurchasingState(address _beneficiary, address _erc20Token, uint _amount) internal override(IndividuallyCappedCrowdsale, Crowdsale) {
    IndividuallyCappedCrowdsale._updateERC20PurchasingState(_beneficiary, _erc20Token, _amount);
  }
  /**
   * @dev Extend parent behavior to update only Currency contributions
   * @param _beneficiary Token purchaser wallet address
   * @param currency Fiat Currency symbol
   * @param _amount Amount of wei contributed
   */
  function _updateCurrencyPurchasingState(address _beneficiary, string calldata currency, uint _amount) internal override(IndividuallyCappedCrowdsale, Crowdsale) {
    IndividuallyCappedCrowdsale._updateCurrencyPurchasingState(_beneficiary, currency, _amount);
  }
  
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import '../libraries/SafeMath.sol';
import '../interfaces/IERC20.sol';

abstract contract Crowdsale {
  using SafeMath for uint;

  // The token being sold
  address public token;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei
  uint public rate;

  // Amount of wei raised
  uint public weiRaised;
  
  // address of KYC Contract
  address public kycContract;

  // The ERC20 tokens being used to buy token
  mapping(address => bool) public supportedERC20Tokens;
  mapping(address => uint) public erc20TokenRaised;

  // The Fiat Currency being used to buy token
  mapping(string => bool) public supportedCurrencies;
  mapping(string => uint) public fiatCurrencyRaised;

  bool public isFinalized = false;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint value, uint amount);
  event Finalized();
  
  constructor(address _kycContract, uint _rate, address _wallet, address _token, address _erc20Token, string memory _currency) {
    require(_rate > 0, 'Invalid Rate');
    require(_wallet != address(0), 'Invalid wallet Address');
    require(_token != address(0), 'Invalid Token Address');
    require(_erc20Token != address(0));
    
    kycContract = _kycContract;
    rate = _rate;
    wallet = _wallet;
    token = _token;
    supportedERC20Tokens[_erc20Token] = true;
    supportedCurrencies[_currency] = true;
  }
  /**
   * @dev Receive function
   */
  receive() external payable {
    // update state
    weiRaised = weiRaised.add(msg.value);
    _buyTokens(msg.sender, msg.value, true);
    _updateWeiPurchasingState(msg.sender, msg.value);
  }
  /**
   * @dev low level token purchase
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {
    // update state
    weiRaised = weiRaised.add(msg.value);
    _buyTokens(_beneficiary, msg.value, true);
    _updateWeiPurchasingState(_beneficiary, msg.value);
  }
  /**
   * @dev low level token purchase
   * @param _beneficiary Address performing the token purchase
   */
  function _buyTokens(address _beneficiary, uint weiAmount, bool weiTransfer) internal {
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint tokens = _getTokenAmount(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

    _updatePurchasingState(_beneficiary, weiAmount);

    if(weiTransfer) {
      _forwardFunds(weiAmount);
    }
    _postValidatePurchase(_beneficiary, weiAmount);
  }
  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(address _beneficiary, uint _weiAmount) internal virtual {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }
  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(address _beneficiary, uint _weiAmount) internal virtual {
  }
  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(address _beneficiary, uint _tokenAmount) internal virtual {
    _deliverTokens(_beneficiary, _tokenAmount);
  }
  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(address _beneficiary, uint _tokenAmount) internal virtual {
    IERC20(token).transfer(_beneficiary, _tokenAmount);
  }
  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(address _beneficiary, uint _weiAmount) internal virtual {
  }
  function _updateWeiPurchasingState(address _beneficiary, uint _weiAmount) internal virtual {
  }
  function _updateERC20PurchasingState(address _beneficiary, address _erc20Token, uint _amount) internal virtual {
  }
  function _updateCurrencyPurchasingState(address _beneficiary, string calldata _currency, uint _amount) internal virtual {
  }
  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint _weiAmount) internal view returns (uint) {
    return _weiAmount.mul(rate);
  }
  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds(uint _weiAmount) internal {
    payable(wallet).transfer(_weiAmount);
  }
  /**
   * @dev enables token transfers, called when owner calls finalize()
  */
  function finalization() internal virtual {
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import './Crowdsale.sol';

abstract contract TimedCrowdsale is Crowdsale {

  uint public openingTime;
  uint public closingTime;

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen {
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

  /**
   * @dev Constructor, takes crowdsale opening and closing times.
   * @param _openingTime Crowdsale opening time
   * @param _closingTime Crowdsale closing time
   */
  constructor(uint _openingTime, uint _closingTime) {
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    return block.timestamp > closingTime;
  }
  /**
   * @dev Extend parent behavior requiring to be within contributing period
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address _beneficiary, uint _weiAmount) internal override virtual onlyWhileOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import './Crowdsale.sol';
import '../tokens/MintableToken.sol';

abstract contract MintedCrowdsale is Crowdsale {
  /**
  * @dev Overrides delivery by minting tokens upon purchase.
  * @param _beneficiary Token purchaser
  * @param _tokenAmount Number of tokens to be minted
  */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal override virtual {
    require(MintableToken(token).mint(_beneficiary, _tokenAmount));
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import './Crowdsale.sol';
import '../interfaces/IKYC.sol';

abstract contract WhitelistedCrowdsale is Crowdsale {

  /**
   * @dev Reverts if beneficiary wallet is not whitelisted. Can be used when extending this contract.
   */
  modifier isWhitelisted(address _beneficiary) {
    require(whitelisted(_beneficiary), 'User not whitelisted');
    _;
  }

  function whitelisted(address _beneficiary) public view returns (bool) {
    return IKYC(kycContract).isWhitelisted(_beneficiary);
  }
  /**
   * @dev Extend parent behavior requiring beneficiary to be in whitelist.
   * @param _beneficiary Token beneficiary
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal override virtual isWhitelisted(_beneficiary) {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import './Crowdsale.sol';
import '../Ownable.sol';
import '../interfaces/IKYC.sol';
import '../libraries/SafeMath.sol';

abstract contract IndividuallyCappedCrowdsale is Crowdsale {
  using SafeMath for uint;

  // Investor Min & Max Cap in contributions
  uint public MinCap = 2000000000000000; // 0.002 ether
  uint public MaxCap = ~uint256(0);
  
  // Track investor contributions
  mapping(bytes32 => uint) internal contributions;
  mapping(bytes32 => uint) internal weiContributions;
  mapping(bytes32 => mapping(address => uint)) internal erc20Contributions;
  mapping(bytes32 => mapping(string => uint)) internal fiatCurrencyContributions;
  mapping(bytes32 => uint) public minCaps;
  mapping(bytes32 => uint) public maxCaps;
  
  /**
   * @dev Returns the cap of a specific user.
   * @param _beneficiary Address whose cap is to be checked
   * @return Current cap for individual user
   */
  function getUserCaps(address _beneficiary) public view returns (uint, uint) {
    bytes32 userId = IKYC(kycContract).getWalletOwner(_beneficiary);
    uint _minCap = minCaps[userId];
    if(_minCap == 0) _minCap = MinCap;
    uint _maxCap = maxCaps[userId];
    if(_maxCap == 0) _maxCap = MaxCap;
    return (_minCap, _maxCap);
  }
  /**
   * @dev Returns the cap of a specific user.
   * @param userId Bytes32 IPFS hash of user whose cap is to be checked
   * @return Current cap for individual user
   */
  function getUserCaps(bytes32 userId) public view returns (uint, uint) {
    uint _minCap = minCaps[userId];
    if(_minCap == 0) _minCap = MinCap;
    uint _maxCap = maxCaps[userId];
    if(_maxCap == 0) _maxCap = MaxCap;
    return (_minCap, _maxCap);
  }
  /**
   * @dev Extend parent behavior requiring purchase to respect the user's funding cap.
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address _beneficiary, uint _weiAmount) internal override virtual {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    bytes32 userId = IKYC(kycContract).getWalletOwner(_beneficiary);
    uint _maxCap = maxCaps[userId];
    if(_maxCap == 0) _maxCap = MaxCap;
    require(contributions[userId].add(_weiAmount) <= _maxCap, 'User Cap exceeded');
    uint _minCap = minCaps[userId];
    if(_minCap == 0) _minCap = MinCap;
    require(contributions[userId].add(_weiAmount) >= _minCap, 'User Cap Too Low');
  }
  /**
   * @dev Extend parent behavior to update user contributions
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _updatePurchasingState(address _beneficiary, uint _weiAmount) internal override virtual {
    super._updatePurchasingState(_beneficiary, _weiAmount);
    bytes32 userId = IKYC(kycContract).getWalletOwner(_beneficiary);
    contributions[userId] = contributions[userId].add(_weiAmount);
  }
  function _updateWeiPurchasingState(address _beneficiary, uint _weiAmount) internal override virtual {
    super._updateWeiPurchasingState(_beneficiary, _weiAmount);
    bytes32 userId = IKYC(kycContract).getWalletOwner(_beneficiary);
    weiContributions[userId] = weiContributions[userId].add(_weiAmount);
  }
  function _updateERC20PurchasingState(address _beneficiary, address _erc20Token, uint _amount) internal override virtual {
    super._updateERC20PurchasingState(_beneficiary, _erc20Token, _amount);
    bytes32 userId = IKYC(kycContract).getWalletOwner(_beneficiary);
    erc20Contributions[userId][_erc20Token] = erc20Contributions[userId][_erc20Token].add(_amount);
  }
  function _updateCurrencyPurchasingState(address _beneficiary, string calldata currency, uint _amount) internal override virtual {
    super._updateCurrencyPurchasingState(_beneficiary, currency, _amount);
    bytes32 userId = IKYC(kycContract).getWalletOwner(_beneficiary);
    fiatCurrencyContributions[userId][currency] = fiatCurrencyContributions[userId][currency].add(_amount);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import "./BasicToken.sol";
import '../Ownable.sol';

abstract contract PausableToken is BasicToken, Ownable {

    event Pause();
    event Unpause();
    bool public paused = false;

    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!isPaused(), 'Token Paused');
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(isPaused(), 'Token Not Paused');
        _;
    }
    /**
     * @dev Returns true if the Token is paused.
     */
    function isPaused() public view returns (bool) {
        return paused;
    }
    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() onlyOwner whenNotPaused external {
        paused = true;
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() onlyOwner whenPaused external {
        paused = false;
        emit Unpause();
    }

    function transfer(address _to, uint _value) public override virtual whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public override virtual whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint _value) public override virtual whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import '../Ownable.sol';
import './BasicToken.sol';
import "../libraries/SafeMath.sol";

abstract contract MintableToken is BasicToken, Ownable {
  using SafeMath for uint;

  event Mint(address indexed to, uint amount);
  event Burn(address indexed burner, uint value);
  
  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint _amount) external onlyOwner returns (bool) {
    require(_amount <= MAX - totalSupply, "Total supply exceeded max limit.");
    totalSupply = totalSupply.add(_amount);
    require(_amount <= MAX - balanceOf[_to], "Balance of owner exceeded max limit.");
    balanceOf[_to] = balanceOf[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Burns a specific amount of tokens.
   * @param _holder The address from which tokens to be burned.
   * @param _value The amount of token to be burned.
   */
  function burn(address _holder, uint _value) external onlyOwner returns (bool) {
    require(_holder != address(0), "Burn from the zero address");
    require(_value <= balanceOf[_holder], 'Burn amount exceeds balance of holder');

    balanceOf[_holder] = balanceOf[_holder].sub(_value);
    require(_value <= totalSupply, "Insufficient total supply.");
    totalSupply = totalSupply.sub(_value);
    emit Burn(_holder, _value);
    emit Transfer(_holder, address(0), _value);
    return true;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a / b;
        return c;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import '../interfaces/IERC20.sol';
import "../libraries/SafeMath.sol";

abstract contract BasicToken is IERC20 {
    using SafeMath for uint;

    uint constant MAX = ~uint256(0);

    uint public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;
   
   /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint _value) public override virtual returns (bool) {
        require(_spender != address(0), "Approve to the invalid or zero address");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

   /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint _value) public override virtual returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

   /**
    * The transferFrom method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf. 
    * This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge fees in sub-currencies. 
    * The function SHOULD throw unless the _from account has deliberately authorized the sender of the message via some mechanism.
    * @param _from address which you want to send tokens from
    * @param _to address which you want to transfer to
    * @param _value uint the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint _value) public override virtual returns (bool success) {
        require(_from != address(0), "Invalid Sender Address");
        require(allowance[_from][_to] >= _value, "Transfer amount exceeds allowance");
        _transfer(_from, _to, _value);
        allowance[_from][_to] = allowance[_from][_to].sub(_value);
        return true;
    }

   /**
    * Internal method that does transfer token from one account to another
    */
    function _transfer(address _sender, address _recipient, uint _amount) internal {
        require(_sender != address(0), "Invalid Sender Address");
        require(_recipient != address(0), "Invalid Recipient Address");
        
        uint balanceAmt = balanceOf[_sender];
        require(balanceAmt >= _amount, "Transfer amount exceeds balance of sender");
        require(_amount <= MAX - balanceOf[_recipient], "Balance limit exceeded for Recipient.");
        
        balanceOf[_sender] = balanceAmt.sub(_amount);
        balanceOf[_recipient] = balanceOf[_recipient].add(_amount);
        
        emit Transfer(_sender, _recipient, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

interface IKYC {
  function kycApproved(bytes32 userid) external view returns (bool);
  function getUserWallets(bytes32 userid) external view returns (address[] memory);
  function isWhitelisted(address wallet) external view returns (bool);
  function getWalletOwner(address wallet) external view returns (bytes32);
  function removeWalletFromWhitelist(address wallet) external;
  function registerUser(bytes32 userIpfsHash, address wallet) external;
  function approveKyc(bytes32 userid) external;
  function revokeKyc(bytes32 userid) external;
}