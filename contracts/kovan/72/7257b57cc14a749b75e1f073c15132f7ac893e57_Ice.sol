// SPDX-License-Identifier: MIT
// Omnus Contracts (contracts/entropy/Ice.sol)
// https://omnuslab.com/icering

// ICE (In Chain Entropy)

pragma solidity ^0.8.13;

/**
* @dev ICE - In-Chain Entropy
*
* This protocol generates in-chain entropy (OK, ON-chain not IN-chain, but that didn't make a cool acronym...).
* Solidity and blockchains are deterministic, so standard warnings apply, this produces pseudorandomness. For very strict levels of 
* randomness the answer remains to go off-chain, but that carries a cost and also introduces an off-chain dependency that could fail or,
* worse, some day be tampered with or become vulnerable. 
* 
* The core premise of this protocol is that we aren't chasing true random (does that even exist? Philosophers?). What we are chasing 
* is a source or sources of entropy that are unpredictable in that they can't practically be controlled or predicted by a single entity.
*
* A key source of entropy in this protocol is contract balances, namely the balances of contracts that change with every block. Think large 
* value wallets, like exchange wallets. We store a list of these contract addresses and every request combine the eth value of these addresses
* with the current block time and a modulo and hash it. 
* 
* Block.timestamp has been used as entropy before, but it has a significant drawback in that it can be controlled by miners. If the incentive is
* high enough a miner could look to control the outcome by controlling the timestamp. 
* 
* When we add into this a variable contract balance we require a single entity be able to control both the block.timestamp and, for example, the 
* eth balance of a binance hot wallet. In the same block. To make it even harder, we loop through our available entropy sources, so the one that
* a transaction uses depends on where in the order we are, which depends on any other txns using this protocol before it. So to be sure of the 
* outcome an entity needs to control the block.timestamp, either control other txns using this in the block or make sure it's the first txn in 
* the block, control the balance of another parties wallet than changes with every block, then be able to hash those known variables to see if the
* outcome is a positive one for them. Whether any entity could achieve that is debatable, but you would imagine that if it is possible it 
* would come at significant cost.
*
* The protocol can be used in two ways: to return a full uin256 of entropy or a number within a given range. Each of these can be called in light,
* standard or heavy mode:
*   Light    - uses the balance of the last contract loaded into the entropy list for every generation. This reduces storage reads
*              at the disadvantage of reducing the variability of the seed.
*   Standard - increments through our list of sources using a different one as the seed each time, returning to the first item at the end of the 
*              loop and so on.
*   Heavy    - creates a hash of hashes using ALL of the entropy seed sources. In principle this would require a single entity to control both
*              the block timestamp and the precise balances of a range of addresses within that block. 
*
*                                                             D I S C L A I M E R
*                                                             ===================    
*                   Use at your own risk, obvs. I've tried hard to make this good quality entropy, but whether random exists is
*                   a question for philosophers not solidity devs. If there is a lot at stake on whatever it is you are doing 
*                   please DYOR on what option is best for you. No liability is accepted etc.
*/

import "@openzeppelin/contracts/access/Ownable.sol";  
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@omnus/contracts/entropy/IIce.sol";  
import "@omnus/contracts/storage/OmStorage.sol"; 
import "@omnus/contracts/token/ERC20Spendable/ERC20SpendableReceiver.sol"; 

contract Ice is Ownable, OmStorage, ERC20SpendableReceiver, IIce {
  using SafeERC20 for IERC20;
  
  uint256 constant NUMBER_IN_RANGE_LIGHT = 0;
  uint256 constant NUMBER_IN_RANGE_STANDARD = 1;
  uint256 constant NUMBER_IN_RANGE_HEAVY = 2;
  uint256 constant ENTROPY_LIGHT = 3;
  uint256 constant ENTROPY_STANDARD = 4;
  uint256 constant ENTROPY_HEAVY = 5;

  address public treasury;
  /**
  *
  * @dev entropyItem mapping holds the list of addresses for the contract balances we use as entropy seeds:
  *
  */
  mapping (uint256 => address) entropyItem;

  /**
  *
  * @dev Constructor must be passed the address for the ERC20 that is the designated spendable item for this protocol. Access
  * to the protocol is relayed via the spendable ERC20 even if there is no fee for use:
  * 
  * This contract makes use of OmStorage to greatly reduce storage costs, both read and write. A single uint256 is used as a
  * 'bitmap' for underlying config values, meaning a single read and write is required in all cases. For more details see
  * contracts/storage/OmStorage.sol.
  *
  */
  constructor(address _ERC20Spendable)
    ERC20SpendableReceiver(_ERC20Spendable)
    OmStorage(2, 2, 8, 49, 10, 2, 2, 0, 0, 0, 0, 0) {
    encodeNus(0, 0, 10000000, 0, 0, 0, 0, 0, 0, 0, 0, 0);
  }

  /**
  *
  * @dev Standard entry point for all calls relayed via the payable ERC20. 
  *
  */
  function receiveSpendableERC20(address, uint256 _tokenPaid, uint256[] memory _arguments) override external onlyERC20Spendable(msg.sender) returns(bool, uint256[] memory) { 
    
    (uint256 seedIndex, uint256 counter, uint256 modulo, address seedAddress, uint256 feeBase, uint256 ethExponent, uint256 oatExponent) = getConfig();

    uint256 oatFee = feeBase * (10 ** oatExponent);

    if (oatFee != 0) {
      require(_tokenPaid == oatFee, "Incorrect ERC20 payment");
    }

    uint256[] memory returnResults = new uint256[](1);

    /**
    *
    * @dev Number in range request, send with light / normal / heavy designation:
    *
    */
    if (_arguments[0] == NUMBER_IN_RANGE_LIGHT) {
      returnResults[0] = getNumberInRangeLight(_arguments[1], seedIndex, counter, modulo, seedAddress, feeBase, ethExponent, oatExponent); 
      return(true, returnResults);
    }
    if (_arguments[0] == NUMBER_IN_RANGE_STANDARD) {
      returnResults[0] = getNumberInRange(_arguments[1], seedIndex, counter, modulo, seedAddress, feeBase, ethExponent, oatExponent); 
      return(true, returnResults);
    }

    if (_arguments[0] == NUMBER_IN_RANGE_HEAVY) {
      returnResults[0] = getNumberInRangeHeavy(_arguments[1], seedIndex, counter, modulo, seedAddress, feeBase, ethExponent, oatExponent); 
      return(true, returnResults);
    }

    /**
    *
    * @dev Standard entropy request, send with light / normal / heavy designation:
    *
    */
    if (_arguments[0] == ENTROPY_LIGHT) {
      returnResults[0] = getEntropyLight(seedIndex, counter, modulo, seedAddress, feeBase, ethExponent, oatExponent); 
      return(true, returnResults);
    }
    if (_arguments[0] == ENTROPY_STANDARD) {
      returnResults[0] = getEntropy(seedIndex, counter, modulo, seedAddress, feeBase, ethExponent, oatExponent); 
      return(true, returnResults);
    }

    if (_arguments[0] == ENTROPY_HEAVY) {
      returnResults[0] = getEntropyHeavy(seedIndex, counter, modulo, seedAddress, feeBase, ethExponent, oatExponent); 
      return(true, returnResults);
    }  

    return(false, returnResults);
  }

  /**
  *
  * @dev Standard entry point for direct call, number in range
  *
  */
  function iceRingNumberInRange(uint256 _mode, uint256 _upperBound) external payable returns(bool, uint256 numberInRange_) {  

    (uint256 seedIndex, uint256 counter, uint256 modulo, address seedAddress, uint256 feeBase, uint256 ethExponent, uint256 oatExponent) = getConfig();

    uint256 ethFee = feeBase * (10 ** ethExponent);

    if (ethFee != 0) {
      require(msg.value == ethFee, "Incorrect ETH payment");
    }

    /**
    *
    * @dev Number in range request, send with light / normal / heavy designation:
    *
    */
    if (_mode == NUMBER_IN_RANGE_LIGHT) {

      return(true, getNumberInRangeLight(_upperBound, seedIndex, counter, modulo, seedAddress, feeBase, ethExponent, oatExponent));
    
    }
    if (_mode == NUMBER_IN_RANGE_STANDARD) {

      return(true, getNumberInRange(_upperBound, seedIndex, counter, modulo, seedAddress, feeBase, ethExponent, oatExponent));

    }

    if (_mode == NUMBER_IN_RANGE_HEAVY) {

      return(true, getNumberInRangeHeavy(_upperBound, seedIndex, counter, modulo, seedAddress, feeBase, ethExponent, oatExponent)); 

    }

    return(false, 0);
  }

  /**
  *
  * @dev Standard entry point for direct call, entropy
  *
  */
  function iceRingEntropy(uint256 _mode) external payable returns(bool, uint256 entropy_) { 

    (uint256 seedIndex, uint256 counter, uint256 modulo, address seedAddress, uint256 feeBase, uint256 ethExponent, uint256 oatExponent) = getConfig();

    uint256 ethFee = feeBase * (10 ** ethExponent);

    if (ethFee != 0) {
      require(msg.value == ethFee, "Incorrect ETH payment");
    }

    /**
    *
    * @dev Standard entropy request, send with light / normal / heavy designation:
    *
    */
    if (_mode == ENTROPY_LIGHT) {

      return(true, getEntropyLight(seedIndex, counter, modulo, seedAddress, feeBase, ethExponent, oatExponent));

    }

    if (_mode == ENTROPY_STANDARD) {

      return(true, getEntropy(seedIndex, counter, modulo, seedAddress, feeBase, ethExponent, oatExponent));

    }

    if (_mode == ENTROPY_HEAVY) {

      return(true, getEntropyHeavy(seedIndex, counter, modulo, seedAddress, feeBase, ethExponent, oatExponent));

    }  

    return(false, 0);

  }


  /**
  *
  * @dev View details of a given entropy seed address:
  *
  */
  function viewEntropyAddress(uint256 _index) external view returns (address entropyAddress) {
    return (entropyItem[_index]) ;
  }

  /**
  *
  * @dev get ETH fee
  *
  */
  function getEthFee() external view returns (uint256 ethFee) {
    return (getOm05() * (10 ** getOm06())) ;
  }

  /**
  *
  * @dev get OAT fee
  *
  */
  function getOatFee() external view returns (uint256 oatFee) {
    return (getOm05() * (10 ** getOm07())) ;
  }
  
  /**
  *
  * @dev Owner can add entropy seed address:
  *
  */
  function addEntropy(address _entropyAddress) external onlyOwner {

    (uint256 seedIndex, uint256 counter, uint256 modulo, address seedAddress, uint256 feeBase, uint256 ethExponent, uint256 oatExponent) = getConfig();

    counter += 1;
    entropyItem[counter] = _entropyAddress;
    seedAddress = _entropyAddress;
    emit EntropyAdded(_entropyAddress);
    encodeNus(seedIndex, counter, modulo, uint256(uint160(seedAddress)), feeBase, ethExponent, oatExponent, 0, 0, 0, 0, 0);
  }

  /**
  *
  * @dev Owner can update entropy seed address:
  *
  */
  function updateEntropy(uint256 _index, address _newAddress) external onlyOwner {
    address oldEntropyAddress = entropyItem[_index];
    entropyItem[_index] = _newAddress;
    emit EntropyUpdated(_index, _newAddress, oldEntropyAddress); 
  }

  /**
  *
  * @dev Owner can clear the list to start again:
  *
  */
  function deleteAllEntropy() external onlyOwner {
    (uint256 seedIndex, uint256 counter, uint256 modulo, address seedAddress, uint256 feeBase, uint256 ethExponent, uint256 oatExponent) = getConfig();

    require(counter > 0, "No entropy defined");
    for (uint i = 1; i <= counter; i++){
      delete entropyItem[i];
    }
    counter = 0;
    seedAddress = address(0);
    encodeNus(seedIndex, counter, modulo, uint256(uint160(seedAddress)), feeBase, ethExponent, oatExponent, 0, 0, 0, 0, 0);
    emit EntropyCleared();
  }

  /**
  *
  * @dev Owner can update the base fee
  *
  */
  function updateBaseFee(uint256 _newBaseFee) external onlyOwner {
    (uint256 seedIndex, uint256 counter, uint256 modulo, address seedAddress, uint256 oldFeeBase, uint256 ethExponent, uint256 oatExponent) = getConfig(); 
    
    encodeNus(seedIndex, counter, modulo, uint256(uint160(seedAddress)), _newBaseFee, ethExponent, oatExponent, 0, 0, 0, 0, 0);
    
    emit BaseFeeUpdated(oldFeeBase, _newBaseFee);
  }

  /**
  *
  * @dev Owner can update the ETH fee exponent
  *
  */
  function updateETHFeeExponent(uint256 _newEthExponent) external onlyOwner {
    (uint256 seedIndex, uint256 counter, uint256 modulo, address seedAddress, uint256 feeBase, uint256 oldEthExponent, uint256 oatExponent) = getConfig(); 
    
    encodeNus(seedIndex, counter, modulo, uint256(uint160(seedAddress)), feeBase, _newEthExponent, oatExponent, 0, 0, 0, 0, 0);
    
    emit ETHExponentUpdated(oldEthExponent, _newEthExponent);
  }

  /**
  *
  * @dev Owner can update the OAT fee exponent
  *
  */
  function updateOATFeeExponent(uint256 _newOatExponent) external onlyOwner {
    (uint256 seedIndex, uint256 counter, uint256 modulo, address seedAddress, uint256 feeBase, uint256 ethExponent, uint256 oldOatExponent) = getConfig(); 
    
    encodeNus(seedIndex, counter, modulo, uint256(uint160(seedAddress)), feeBase, ethExponent, _newOatExponent, 0, 0, 0, 0, 0);
    
    emit OATExponentUpdated(oldOatExponent, _newOatExponent);
  }

  /** 
  *
  * @dev owner can update treasury address:
  *
  */ 
  function setTreasury(address _treasury) external onlyOwner {
    treasury = _treasury;
    emit TreasurySet(_treasury);
  }

  /**
  *
  * @dev Create hash of entropy seeds:
  *
  */
  function _hashEntropy(bool lightMode, uint256 seedIndex, uint256 counter, uint256 modulo, address seedAddress, uint256  feeBase, uint256 ethExponent, uint256 oatExponent) internal returns(uint256 hashedEntropy_){

    if (modulo >= 99999999) {
      modulo = 10000000;
    }  
    else {
      modulo = modulo + 1; 
    } 

    if (lightMode) {
      hashedEntropy_ = (uint256(keccak256(abi.encode(seedAddress.balance + (block.timestamp % modulo)))));
    }
    else {
      if (seedIndex >= counter) {
      seedIndex = 1;
      }  
      else {
        seedIndex += 1; 
      } 
      address rotatingSeedAddress = entropyItem[seedIndex];
      uint256 seedAddressBalance = rotatingSeedAddress.balance;
      hashedEntropy_ = (uint256(keccak256(abi.encode(seedAddressBalance, (block.timestamp % modulo)))));
      emit EntropyServed(rotatingSeedAddress, seedAddressBalance, block.timestamp, modulo, hashedEntropy_); 
    }         

    encodeNus(seedIndex, counter, modulo, uint256(uint160(seedAddress)), feeBase, ethExponent, oatExponent, 0, 0, 0, 0, 0);
      
    return(hashedEntropy_);
  }

  /**
  *
  * @dev Find a number within a range:
  *
  */
  function _numberInRange(uint256 _upperBound, bool _lightMode, uint256 _seed, uint256 _counter, uint256 _modulo, address _seedAddress, uint256 _feeBase, uint256 _ethExponent, uint256 _oatExponent) internal returns(uint256 numberWithinRange){
    return((((_hashEntropy(_lightMode, _seed, _counter, _modulo, _seedAddress, _feeBase, _ethExponent, _oatExponent) % 10 ** 18) * _upperBound) / (10 ** 18)) + 1);
  }

  /**
  *
  * @dev Get OM values from the NUS
  *
  */
  function getConfig() public view returns(uint256 seedIndex_, uint256 counter_, uint256 modulo_, address seedAddress_, uint256 feeBase_, uint256 ethExponent_, uint256 oatExponent_){
    
    uint256 nusInMemory = nus;

    return(om1Value(nusInMemory), om2Value(nusInMemory), om3Value(nusInMemory), address(uint160(om4Value(nusInMemory))), om5Value(nusInMemory), om6Value(nusInMemory), om7Value(nusInMemory));
  }

  /**
  *
  * @dev Return a full uint256 of entropy:
  *
  */
  function getEntropy(uint256 _seed, uint256 _counter, uint256 _modulo, address _seedAddress, uint256  _feeBase, uint256 _ethExponent, uint256 _oatExponent) internal returns(uint256 entropy_){
    entropy_ = _hashEntropy(false, _seed, _counter, _modulo, _seedAddress, _feeBase, _ethExponent, _oatExponent); 
    return(entropy_);
  }

  /**
  *
  * @dev Return a full uint256 of entropy - light mode. Light mode uses the most recent added seed address which is stored
  * in the control NUS. This avoids another read from storage at the cost of not cycling through multiple entropy
  * sources. The normal (non-light) version increments through the seed mapping.
  *
  */
  function getEntropyLight(uint256 _seedIndex,uint256 _counter, uint256 _modulo, address _seedAddress, uint256 _feeBase, uint256 _ethExponent, uint256 _oatExponent) internal returns(uint256 entropy_){
    entropy_ = _hashEntropy(true, _seedIndex, _counter, _modulo, _seedAddress, _feeBase, _ethExponent, _oatExponent); 
    return(entropy_);
  }

  /**
  *
  * @dev Return a full uint256 of entropy - heavy mode. Heavy mode looks to maximise the number of sources of entropy that an
  * entity would need to control in order to predict an outome. It creates a hash of all our entropy sources, 1 to n, hashed with
  * the block.timestamp altered by an increasing modulo.
  *
  */
  function getEntropyHeavy(uint256, uint256 _counter, uint256 _modulo, address _seedAddress, uint256  _feeBase, uint256 _ethExponent, uint256 _oatExponent) internal returns(uint256 entropy_){
    
    uint256 loopEntropy;

    for (uint i = 0; i < _counter; i++){
      loopEntropy = _hashEntropy(false, i, _counter, _modulo, _seedAddress, _feeBase, _ethExponent, _oatExponent); 
      entropy_ = (uint256(keccak256(abi.encode(entropy_, loopEntropy))));
    }
    return(entropy_);

  }

  /**
  *
  * @dev Return a number within a range (1 to upperBound):
  *
  */
  function getNumberInRange(uint256 _upperBound, uint256 _seedIndex, uint256 _counter, uint256 _modulo, 
      address _seedAddress, uint256 _feeBase, uint256 _ethExponent, uint256 _oatExponent) internal returns(uint256 numberInRange_){
    numberInRange_ = _numberInRange(_upperBound, false, _seedIndex, _counter, _modulo, _seedAddress, _feeBase, _ethExponent, _oatExponent);
    return(numberInRange_);
  }

  /**
  *
  * @dev Return a number within a range (1 to upperBound) - light mode. Light mode uses the most recent added seed address which is stored
  * in Om Storage. This avoids another read from storage at the cost of not cycling through multiple entropy
  * sources. The normal (non-light) version increments through the seed mapping.
  *
  */
  function getNumberInRangeLight(uint256 _upperBound, uint256 _seedIndex, uint256 _counter, uint256 _modulo, 
      address _seedAddress, uint256 _feeBase, uint256 _ethExponent, uint256 _oatExponent) internal returns(uint256 numberInRange_){
    numberInRange_ = _numberInRange(_upperBound, true, _seedIndex, _counter, _modulo, _seedAddress, _feeBase, _ethExponent, _oatExponent);
    return(numberInRange_);
  }

  /**
  *
  * @dev Return a number within a range (1 to upperBound) - heavy mode.
  *
  */
  function getNumberInRangeHeavy(uint256 _upperBound, uint256 _seedIndex, uint256 _counter, uint256 _modulo, 
      address _seedAddress, uint256 _feeBase, uint256 _ethExponent, uint256 _oatExponent) internal returns(uint256 numberInRange_){
    numberInRange_ = ((((getEntropyHeavy(_seedIndex, _counter, _modulo, _seedAddress, _feeBase, _ethExponent, _oatExponent) % 10 ** 18) * _upperBound) / (10 ** 18)) + 1);
    return(numberInRange_);
  }

  /**
  *
  * @dev Validate proof:
  *
  */
  function validateProof(uint256 _seedValue, uint256 _modulo, uint256 _timeStamp, uint256 _entropy) external pure returns(bool valid){
    if (uint256(keccak256(abi.encode(_seedValue, (_timeStamp % _modulo)))) == _entropy) return true;
    else return false;
  }

  /**
  *
  * @dev Allow any token payments to be withdrawn:
  *
  */
  function withdrawERC20(IERC20 _token, uint256 _amountToWithdraw) external onlyOwner {
    _token.safeTransfer(treasury, _amountToWithdraw); 
    emit TokenWithdrawal(_amountToWithdraw, address(_token));
  }

  /** 
  * @dev Owner can withdraw eth to treasury:
  */ 
  function withdrawETH(uint256 _amount) external onlyOwner returns (bool) {
    (bool success, ) = treasury.call{value: _amount}("");
    require(success, "Transfer failed.");
    emit EthWithdrawal(_amount); 
    return true;
  }

  /**
  *
  * @dev Revert all eth payments not from the owner or unknown function calls
  *
  */
  receive() external payable {
    require(msg.sender == owner(), "Only owner can fund contract");
  }

  fallback() external payable {
    revert();
  }

}

// SPDX-License-Identifier: MIT
// Omnus Contracts (contracts/token/ERC20Spendable/SpendableERC20Receiver.sol)
// https://omnuslab.com/spendable

// ERC20SpendableReceiver (Lightweight library for allowing contract interaction on token transfer).

pragma solidity ^0.8.13;

/**
*
* @dev ERC20SpendableReceiver - library contract for an ERC20 extension to allow ERC20s to 
* operate as 'spendable' items, i.e. a token that can trigger an action on another contract
* at the same time as being transfered. Similar to ERC677 and the hooks in ERC777, but with more
* of an empasis on interoperability (returned values) than ERC677 and specifically scoped interaction
* rather than the general hooks of ERC777. 
*
* This library contract allows a smart contract to operate as a receiver of ERC20Spendable tokens.
*
*/

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";   
import "@omnus/contracts/token/ERC20Spendable/IERC20SpendableReceiver.sol"; 

/**
*
* @dev ERC20SpendableReceiver.
*
*/
abstract contract ERC20SpendableReceiver is Context, Ownable, IERC20SpendableReceiver {
  
  address public immutable ERC20Spendable; 

  event ERC20Received(address _caller, uint256 _tokenPaid, uint256[] _arguments);

  /** 
  *
  * @dev must be passed the token contract for the payable ERC20:
  *
  */ 
  constructor(address _ERC20Spendable) {
    ERC20Spendable = _ERC20Spendable;
  }

  /** 
  *
  * @dev Only allow authorised token:
  *
  */ 
  modifier onlyERC20Spendable(address _caller) {
    require (_caller == ERC20Spendable, "Call from unauthorised caller");
    _;
  }

  /** 
  *
  * @dev function to be called on receive. Must be overriden, including the addition of a fee check, if required:
  *
  */ 
  function receiveSpendableERC20(address _caller, uint256 _tokenPaid, uint256[] memory _arguments) external virtual onlyERC20Spendable(msg.sender) returns(bool, uint256[] memory) { 
    // Must be overriden 
  }

}

// SPDX-License-Identifier: MIT
// Omnus Contracts (contracts/storage/OmStorage.sol)
// https://omnuslab.com/omstorage
 
// OmStorage (Gas efficient storage)

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Context.sol";  

/**
* @dev OM Storage
* 
* Allows the storage of multiple integers in a single uint256, allowing greatly reduced gas cost for storage.
* For example, rather than defining storage for 12 integers that need to be acccessed individualy, you could use 
* a single storage integer, which needs access only once.
*
* The contract stores a single uint256, the Network Unified Storage, or NUS. This NUS can be broken down into
* units of Operational Memory, called OMs. There can be up to 12 OM in a single NUS.
*
*/

abstract contract OmStorage is Context {

  /**
  *
  * @dev only storage is a single uint256, the NUS:
  *
  */
  uint256 public nus;

  /**
  *
  * @dev mapping details for OMs held as immutable items in the compiled bytecode:
  *
  */
  uint256 private immutable om1Length;
  uint256 private immutable om2Length;
  uint256 private immutable om3Length;
  uint256 private immutable om4Length;
  uint256 private immutable om5Length;
  uint256 private immutable om6Length;
  uint256 private immutable om7Length;
  uint256 private immutable om8Length;
  uint256 private immutable om9Length;
  uint256 private immutable om10Length;
  uint256 private immutable om11Length;
  uint256 private immutable om12Length;

  uint256 private immutable om1Modulo;
  uint256 private immutable om2Modulo;
  uint256 private immutable om3Modulo;
  uint256 private immutable om4Modulo;
  uint256 private immutable om5Modulo;
  uint256 private immutable om6Modulo;
  uint256 private immutable om7Modulo;
  uint256 private immutable om8Modulo;
  uint256 private immutable om9Modulo;
  uint256 private immutable om10Modulo;
  uint256 private immutable om11Modulo;
  uint256 private immutable om12Modulo;

  uint256 private immutable om2Divisor;
  uint256 private immutable om3Divisor;
  uint256 private immutable om4Divisor;
  uint256 private immutable om5Divisor;
  uint256 private immutable om6Divisor;
  uint256 private immutable om7Divisor;
  uint256 private immutable om8Divisor;
  uint256 private immutable om9Divisor;
  uint256 private immutable om10Divisor;
  uint256 private immutable om11Divisor;
  uint256 private immutable om12Divisor;

  /**
  *
  * @dev The contstructor sets up the NUS with the modulo and divisor offsets:
  *
  */
  constructor(uint256 _om1Length, uint256 _om2Length, uint256 _om3Length, uint256 _om4Length, 
    uint256 _om5Length, uint256 _om6Length, uint256 _om7Length, uint256 _om8Length, uint256 _om9Length, 
    uint256 _om10Length, uint256 _om11Length, uint256 _om12Length) {
    
    om1Length  = _om1Length;
    om2Length  = _om2Length;
    om3Length  = _om3Length;
    om4Length  = _om4Length;
    om5Length  = _om5Length;
    om6Length  = _om6Length;
    om7Length  = _om7Length;
    om8Length  = _om8Length;
    om9Length  = _om9Length;
    om10Length = _om10Length;
    om11Length = _om12Length;
    om12Length = _om12Length;

    uint256 moduloExponent;
    uint256 divisorExponent;

    moduloExponent += _om1Length;
    om1Modulo = 10 ** moduloExponent;

    divisorExponent = moduloExponent;
    moduloExponent  += _om2Length;
    om2Divisor      = 10 ** divisorExponent;
    om2Modulo       = 10 ** moduloExponent;

    divisorExponent = moduloExponent;
    moduloExponent  += _om3Length;
    om3Divisor      = 10 ** divisorExponent;
    om3Modulo       = 10 ** moduloExponent;

    divisorExponent = moduloExponent;
    moduloExponent  += _om4Length;
    om4Divisor      = 10 ** divisorExponent;
    om4Modulo       = 10 ** moduloExponent;

    divisorExponent = moduloExponent;
    moduloExponent  += _om5Length;
    om5Divisor      = 10 ** divisorExponent;
    om5Modulo       = 10 ** moduloExponent;

    divisorExponent = moduloExponent;
    moduloExponent  += _om6Length;
    om6Divisor      = 10 ** divisorExponent;
    om6Modulo       = 10 ** moduloExponent;

    divisorExponent = moduloExponent;
    moduloExponent  += _om7Length;
    om7Divisor      = 10 ** divisorExponent;
    om7Modulo       = 10 ** moduloExponent;

    divisorExponent = moduloExponent;
    moduloExponent  += _om8Length;
    om8Divisor      = 10 ** divisorExponent;
    om8Modulo       = 10 ** moduloExponent;

    divisorExponent = moduloExponent;
    moduloExponent  += _om9Length;
    om9Divisor      = 10 ** divisorExponent;
    om9Modulo       = 10 ** moduloExponent;

    divisorExponent = moduloExponent;
    moduloExponent  += _om10Length;
    om10Divisor      = 10 ** divisorExponent;
    om10Modulo       = 10 ** moduloExponent;

    divisorExponent = moduloExponent;
    moduloExponent  += _om11Length;
    om11Divisor      = 10 ** divisorExponent;
    om11Modulo       = 10 ** moduloExponent;

    divisorExponent = moduloExponent;
    moduloExponent  += _om12Length;
    om12Divisor      = 10 ** divisorExponent;
    om12Modulo       = 10 ** moduloExponent;

    require(moduloExponent < 76, "Too wide");
  }

  /**
  *
  * @dev getOmnn function calls return the value for that OM:
  *
  */
  function getOm01() public view returns(uint256 om1_) {
    return(om1Value(nus));
  }
  function getOm02() public view returns(uint256 om2_) {
    return(om2Value(nus));
  }
  function getOm03() public view returns(uint256 om3_) {
    return(om3Value(nus));
  }
  function getOm04() public view returns(uint256 om4_) {
    return(om4Value(nus));
  }
  function getOm05() public view returns(uint256 om5_) {
    return(om5Value(nus));
  }
  function getOm06() public view returns(uint256 om6_) {
    return(om6Value(nus));
  }
  function getOm07() public view returns(uint256 om7_) {
    return(om7Value(nus));
  }
  function getOm08() public view returns(uint256 om8_) {
    return(om8Value(nus));
  }
  function getOm09() public view returns(uint256 om9_) {
    return(om9Value(nus));
  }
  function getOm10() public view returns(uint256 om10_) {
    return(om10Value(nus));
  }
  function getOm11() public view returns(uint256 om11_) {
    return(om11Value(nus));
  }
  function getOm12() public view returns(uint256 om12_) {
    return(om12Value(nus));
  }

  /**
  *
  * @dev omnValue function calls decode a passed NUS value to the OM:
  *
  */
  function om1Value(uint256 _nus) internal view returns(uint256 om1_){
    if (om1Length == 0) return(0);
    return(_nus % om1Modulo);
  }

  function om2Value(uint256 _nus) internal view returns(uint256 om2_) {
    if (om2Length == 0) return(0);
    return((_nus % om2Modulo) / om2Divisor);
  }

  function om3Value(uint256 _nus) internal view returns(uint256 om3_) {
    if (om3Length == 0) return(0);
    return((_nus % om3Modulo) / om3Divisor);
  }

  function om4Value(uint256 _nus) internal view returns(uint256 om4_) {
    if (om4Length == 0) return(0);
    return((_nus % om4Modulo) / om4Divisor);
  }

  function om5Value(uint256 _nus) internal view returns(uint256 om5_) {
    if (om5Length == 0) return(0);
    return((_nus % om5Modulo) / om5Divisor);
  }

  function om6Value(uint256 _nus) internal view returns(uint256 om6_) {
    if (om6Length == 0) return(0);
    return((_nus % om6Modulo) / om6Divisor);
  }

  function om7Value(uint256 _nus) internal view returns(uint256 om7_) {
    if (om7Length == 0) return(0);
    return((_nus % om7Modulo) / om7Divisor);
  }

  function om8Value(uint256 _nus) internal view returns(uint256 om8_) {
    if (om8Length == 0) return(0);
    return((_nus % om8Modulo) / om8Divisor);
  }

  function om9Value(uint256 _nus) internal view returns(uint256 om9_) {
    if (om9Length == 0) return(0);
    return((_nus % om9Modulo) / om9Divisor);
  }

  function om10Value(uint256 _nus) internal view returns(uint256 om10_) {
    if (om10Length == 0) return(0);
    return((_nus % om10Modulo) / om10Divisor);
  }

  function om11Value(uint256 _nus) internal view returns(uint256 om11_) {
    if (om11Length == 0) return(0);
    return((_nus % om11Modulo) / om11Divisor); 
  }

  function om12Value(uint256 _nus) internal view returns(uint256 om12_) {
    if (om12Length == 0) return(0);
    return((_nus % om12Modulo) / om12Divisor);  
  }

  /**
  *
  * @dev Decode the full NUS into OMs
  *
  */
  function decodeNus() public view returns(uint256 om1, uint256 om2, uint256 om3, uint256 om4, uint256 om5, 
  uint256 om6, uint256 om7, uint256 om8, uint256 om9, uint256 om10, uint256 om11, uint256 om12){

    uint256 _nus = nus;

    om1 = om1Value(_nus);
    if (om2Length == 0)  return(om1, om2, om3, om4, om5, om6, om7, om8, om9, om10, om11, om12);
      om2 = om2Value(_nus);
    if (om3Length == 0)  return(om1, om2, om3, om4, om5, om6, om7, om8, om9, om10, om11, om12);
      om3 = om3Value(_nus);
    if (om4Length == 0)  return(om1, om2, om3, om4, om5, om6, om7, om8, om9, om10, om11, om12);
      om4 = om4Value(_nus);
    if (om5Length == 0)  return(om1, om2, om3, om4, om5, om6, om7, om8, om9, om10, om11, om12);
      om5 = om5Value(_nus);
    if (om6Length == 0)  return(om1, om2, om3, om4, om5, om6, om7, om8, om9, om10, om11, om12);
      om6 = om6Value(_nus);
    if (om7Length == 0)  return(om1, om2, om3, om4, om5, om6, om7, om8, om9, om10, om11, om12);
      om7 = om7Value(_nus);
    if (om8Length == 0)  return(om1, om2, om3, om4, om5, om6, om7, om8, om9, om10, om11, om12);
      om8 = om8Value(_nus);
    if (om9Length == 0)  return(om1, om2, om3, om4, om5, om6, om7, om8, om9, om10, om11, om12);
      om9 = om9Value(_nus);
    if (om10Length == 0) return(om1, om2, om3, om4, om5, om6, om7, om8, om9, om10, om11, om12);
      om10 = om10Value(_nus);
    if (om11Length == 0) return(om1, om2, om3, om4, om5, om6, om7, om8, om9, om10, om11, om12);
      om11 = om11Value(_nus);
    if (om12Length == 0) return(om1, om2, om3, om4, om5, om6, om7, om8, om9, om10, om11, om12);
      om12 = om12Value(_nus);
    return(om1, om2, om3, om4, om5, om6, om7, om8, om9, om10, om11, om12);
  }

  /**
  *
  * @dev Encode the OMs to the NUS
  *
  */
  function encodeNus(uint256 _om1, uint256 _om2, uint256 _om3, uint256 _om4, uint256 _om5, 
  uint256 _om6, uint256 _om7, uint256 _om8, uint256 _om9, uint256 _om10, uint256 _om11, uint256 _om12) internal {
    checkOverflow(_om1,_om2, _om3, _om4, _om5, _om6, _om7, _om8, _om9, _om10, _om11, _om12);
    nus = sumOmNus (_om1,_om2, _om3, _om4, _om5, _om6, _om7, _om8, _om9, _om10, _om11, _om12);      
  }

  /**
  *
  * @dev Sum variables
  *
  */
  function sumOmNus(uint256 _om1, uint256 _om2, uint256 _om3, uint256 _om4, uint256 _om5, 
  uint256 _om6, uint256 _om7, uint256 _om8, uint256 _om9, uint256 _om10, uint256 _om11, uint256 _om12) view internal returns(uint256 nus_) {
    nus_ = _om1;
    if (om2Length == 0)  return(nus_);
    nus_ += _om2 * om2Divisor;
    if (om3Length == 0)  return(nus_);
    nus_ += _om3 * om3Divisor;
    if (om4Length == 0)  return(nus_);
    nus_ += _om4 * om4Divisor;
    if (om5Length == 0)  return(nus_);
    nus_ += _om5 * om5Divisor;
    if (om6Length == 0)  return(nus_);
    nus_ += _om6 * om6Divisor;
    if (om7Length == 0)  return(nus_);
    nus_ += _om7 * om7Divisor;
    if (om8Length == 0)  return(nus_);
    nus_ += _om8 * om8Divisor;
    if (om9Length == 0)  return(nus_);
    nus_ += _om9 * om9Divisor;
    if (om10Length == 0)  return(nus_);
    nus_ += _om10 * om10Divisor;
    if (om11Length == 0)  return(nus_);
    nus_ += _om11 * om11Divisor;
    if (om12Length == 0)  return(nus_);
    nus_ += _om12 * om12Divisor;
    return(nus_);
  }        

  /**
  *
  * @dev Check for OM overflow
  *
  */
  function checkOverflow(uint256 _om1, uint256 _om2, uint256 _om3, uint256 _om4, uint256 _om5, 
  uint256 _om6, uint256 _om7, uint256 _om8, uint256 _om9, uint256 _om10, uint256 _om11, uint256 _om12) view internal {
    
    require((_om1  / (10 ** om1Length) == 0),  "om1 overflow");
    if (om2Length == 0) return;
    require((_om2  / (10 ** om2Length) == 0),  "om2 overflow");
    if (om3Length == 0) return;
    require((_om3  / (10 ** om3Length) == 0),  "om3 overflow");
    if (om4Length == 0) return;
    require((_om4  / (10 ** om4Length) == 0),  "om4 overflow");   
    if (om5Length == 0) return;
    require((_om5  / (10 ** om5Length) == 0),  "om5 overflow"); 
    if (om6Length == 0) return;
    require((_om6  / (10 ** om6Length) == 0),  "om6 overflow");
    if (om7Length == 0) return;
    require((_om7  / (10 ** om7Length) == 0),  "om7 overflow");
    if (om8Length == 0) return;
    require((_om8  / (10 ** om8Length) == 0),  "om8 overflow");
    if (om9Length == 0) return;
    require((_om9  / (10 ** om9Length) == 0),  "om9 overflow");
    if (om10Length == 0) return;
    require((_om10 / (10 ** om10Length) == 0), "om10 overflow");
    if (om11Length == 0) return;
    require((_om11 / (10 ** om11Length) == 0), "om11 overflow");
    if (om2Length == 0) return;
    require((_om12 / (10 ** om12Length) == 0), "om12 overflow"); 
  }
}

// SPDX-License-Identifier: MIT
// Omnus Contracts (contracts/entropy/IIce.sol)
// https://omnuslab.com/icering

// IIce (In Chain Entropy - Interface)

pragma solidity ^0.8.13;

/**
* @dev ICE - In-Chain Entropy
*
* This protocol generates in-chain entropy (OK, ON-chain not in-chain, but that didn't make a cool acronym...).
* Solidity and blockchains are deterministic, so standard warnings apply, this produces pseudorandomness. For very strict levels of 
* randomness the answer remains to go off-chain, but that carries a cost and also introduces an off-chain dependency that could fail or,
* worse, some day be tampered with or become vulnerable. 
* 
* The core premise of this protocol is that we aren't chasing true random (does that even exist? Philosophers?). What we are chasing 
* is a source or sources of entropy that are unpredictable in that they can't practically be controlled or predicted by a single entity.
*
* A key source of entropy in this protocol is contract balances, namely the balances of contracts that change with every block. Think large 
* value wallets, like exchange wallets. We store a list of these contract addresses and every request combine the eth value of these addresses
* with the current block time and a modulo and hash it. 
* 
* Block.timestamp has been used as entropy before, but it has a significant drawback in that it can be controlled by miners. If the incentive is
* high enough a miner could look to control the outcome by controlling the timestamp. 
* 
* When we add into this a variable contract balance we require a single entity be able to control both the block.timestamp and, for example, the 
* eth balance of a binance hot wallet. In the same block. To make it even harder, we loop through our available entropy sources, so the one that
* a transaction uses depends on where in the order we are, which depends on any other txns using this protocol before it. So to be sure of the 
* outcome an entity needs to control the block.timestamp, either control other txns using this in the block or make sure it's the first txn in 
* the block, control the balance of another parties wallet than changes with every block, then be able to hash those known variables to see if the
* outcome is a positive one for them. Whether any entity could achieve that is debatable, but you would imagine that if it is possible it 
* would come at significant cost.
*
* The protocol can be used in two ways: to return a full uin256 of entropy or a number within a given range. Each of these can be called in light,
* standard or heavy mode:
*   Light    - uses the balance of the last contract loaded into the entropy list for every generation. This reduces storage reads
*              at the disadvantage of reducing the variability of the seed.
*   Standard - increments through our list of sources using a different one as the seed each time, returning to the first item at the end of the 
*              loop and so on.
*   Heavy    - creates a hash of hashes using ALL of the entropy seed sources. In principle this would require a single entity to control both
*              the block timestamp and the precise balances of a range of addresses within that block. 
*
*                                                             D I S C L A I M E R
*                                                             ===================    
*                   Use at your own risk, obvs. I've tried hard to make this good quality entropy, but whether random exists is
*                   a question for philosophers not solidity devs. If there is a lot at stake on whatever it is you are doing 
*                   please DYOR on what option is best for you. No liability is accepted etc.
*/

/**
*
* @dev Implementation of the Ice interface.
*
*/

interface IIce {
  event EntropyAdded (address _entropyAddress);
  event EntropyUpdated (uint256 _index, address _newAddress, address _oldAddress); 
  event EntropyCleared (); 
  event EntropyServed(address seedAddress, uint256 seedValue, uint256 timeStamp, uint256 modulo, uint256 entropy);
  event BaseFeeUpdated(uint256 oldFee, uint256 newFee);
  event ETHExponentUpdated(uint256 oldETHExponent, uint256 newETHExponent);
  event OATExponentUpdated(uint256 oldOATExponent, uint256 newOATExponent);
  event TreasurySet(address treasury);
  event TokenWithdrawal(uint256 indexed withdrawal, address indexed tokenAddress);
  event EthWithdrawal(uint256 indexed withdrawal);

  function iceRingEntropy(uint256 _mode) external payable returns(bool, uint256 entropy_);
  function iceRingNumberInRange(uint256 _mode, uint256 _upperBound) external payable returns(bool, uint256 numberInRange_);
  function viewEntropyAddress(uint256 _index) external view returns (address entropyAddress);
  function addEntropy(address _entropyAddress) external;
  function updateEntropy(uint256 _index, address _newAddress) external;
  function deleteAllEntropy() external;
  function updateBaseFee(uint256 _newBasefee) external;
  function updateOATFeeExponent(uint256 _newOatExponent) external;
  function updateETHFeeExponent(uint256 _newEthExponent) external;
  function getConfig() external view returns(uint256 seedIndex_, uint256 counter_, uint256 modulo_, address seedAddress_, uint256 baseFee_, uint256 ethExponent_, uint256 oatExponent_);
  function getEthFee() external view returns (uint256 ethFee);
  function getOatFee() external view returns (uint256 oatFee); 
  function validateProof(uint256 _seedValue, uint256 _modulo, uint256 _timeStamp, uint256 _entropy) external pure returns(bool valid);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: MIT
// Omnus Contracts (contracts/token/ERC20Spendable/ISpendableERC20.sol)
// https://omnuslab.com/spendable

// IERC20SpendableReceiver - Interface definition for contracts to implement spendable ERC20 functionality

pragma solidity ^0.8.13;

/**
*
* @dev IERC20SpendableReceiver - library contract for an ERC20 extension to allow ERC20s to 
* operate as 'spendable' items, i.e. a token that can trigger an action on another contract
* at the same time as being transfered. Similar to ERC677 and the hooks in ERC777, but with more
* of an empasis on interoperability (returned values) than ERC677 and specifically scoped interaction
* rather than the general hooks of ERC777. 
*
* This library contract allows a smart contract to operate as a receiver of ERC20Spendable tokens.
*
* Interface Definition IERC20SpendableReceiver
*
*/

interface IERC20SpendableReceiver{

  /** 
  *
  * @dev function to be called on receive. 
  *
  */ 
  function receiveSpendableERC20(address _caller, uint256 _tokenPaid, uint256[] memory arguments) external returns(bool, uint256[] memory);

}