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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

abstract contract Asic {
  event Transfer(address indexed from, address indexed to, uint256 value);

  function balanceOf(address account) public view virtual returns (uint256);
  function transfer(address to, uint256 amount) public virtual returns (bool);
}

/*
     _____________________________________________________________________________________
    (__   ___________________________________________________________________________   __)
       | |                                                                           | |
       | |                         ███████╗███╗   ██╗██████╗                         | |
       | |                         ██╔════╝████╗  ██║██╔══██╗                        | |
       | |                         █████╗  ██╔██╗ ██║██║  ██║                        | |
       | |                         ██╔══╝  ██║╚██╗██║██║  ██║                        | |
       | |                         ███████╗██║ ╚████║██████╔╝                        | |
       | |                         ╚══════╝╚═╝  ╚═══╝╚═════╝                         | |
       | |                                                                           | |
       | |                         █████╗ ███████╗██╗ ██████╗                        | |
       | |                        ██╔══██╗██╔════╝██║██╔════╝                        | |
       | |                        ███████║███████╗██║██║                             | |
       | |                        ██╔══██║╚════██║██║██║                             | |
       | |                        ██║  ██║███████║██║╚██████╗                        | |
       | |                        ╚═╝  ╚═╝╚══════╝╚═╝ ╚═════╝                        | |
       | |                                                                           | |
       | |             ███╗   ███╗██╗███╗   ██╗███████╗██████╗ ███████╗              | |
       | |             ████╗ ████║██║████╗  ██║██╔════╝██╔══██╗██╔════╝              | |
       | |             ██╔████╔██║██║██╔██╗ ██║█████╗  ██████╔╝███████╗              | |
       | |             ██║╚██╔╝██║██║██║╚██╗██║██╔══╝  ██╔══██╗╚════██║              | |
       | |             ██║ ╚═╝ ██║██║██║ ╚████║███████╗██║  ██║███████║              | |
       | |             ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚══════╝              | |
 ______| |___________________________________________________________________________| |_______
(_   ______________________________________________________________________________________   _)
  | |                                                                                      | |
  | |  _                           _     _     _                              _            | |
  | | | |__  _ __ ___  _   _  __ _| |__ | |_  | |_ ___    _   _  ___  _   _  | |__  _   _  | |
  | | | '_ \| '__/ _ \| | | |/ _` | '_ \| __| | __/ _ \  | | | |/ _ \| | | | | '_ \| | | | | |
  | | | |_) | | | (_) | |_| | (_| | | | | |_  | || (_) | | |_| | (_) | |_| | | |_) | |_| | | |
  | | |_.__/|_|  \___/ \__,_|\__, |_| |_|\__|  \__\___/   \__, |\___/ \__,_| |_.__/ \__, | | |
  | |                        |___/                        |___/                     |___/  | |
  | |        _  __          _                _______ _            _____                    | |
  | |       | |/ /         | |              |__   __| |          |  __ \                   | |
  | |       | ' / ___  _ __| | _____ _   _     | |  | |__   ___  | |  | | _____   __       | |
  | |       |  < / _ \| '__| |/ / _ \ | | |    | |  | '_ \ / _ \ | |  | |/ _ \ \ / /       | |
  | |       | . \ (_) | |  |   <  __/ |_| |    | |  | | | |  __/ | |__| |  __/\ V /        | |
  | |       |_|\_\___/|_|  |_|\_\___|\__, |    |_|  |_| |_|\___| |_____/ \___| \_/         | |
  | |                                 __/ |                                                | |
  | |                                |___/                                                 | |
 _| |______________________________________________________________________________________| |_
(______________________________________________________________________________________________)

*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./PulseBitcoin.sol";
import "./Asic.sol";

contract EndASICMiners is Ownable {

  // PLSB Token abstract
  PulseBitcoin public immutable PLSB;

  // ASIC Token abstract
  Asic public immutable ASIC;

  // Our own custom event. Potentially useful for future iterations of the dapp
  event EndMinerError(uint256 minerId, string reason);

  // PLSB Event for successfull minerEnd
  event MinerEnd(uint256 data0, uint256 data1, address indexed accountant, uint40 indexed minerId);

  // Generic Event
  event Transfer(address indexed from, address indexed to, uint256 value);

  // Storage for all the claims mapped by PLSB.currentDay => claimer => claims
  mapping(uint256 => mapping(address => uint256)) public senderSums;

  // Fee the receiver takes from the asicReturn (owner modifiable)
  uint96 public asicFee;

  // The max amount of ASIC that can be claimed per day by one wallet (including fee)
  uint256 private _maxAsicPerDay;

  // The address of the reciever
  address public receiverAddress;

  // Should the ASIC fee be sent to the reciever or to the caller?
  bool public sendFundsToReceiver;

  // PLSB error selectors
  bytes4 private minerListEmptyError = PulseBitcoin.MinerListEmpty.selector;
  bytes4 private invalidMinerIndexError = PulseBitcoin.InvalidMinerIndex.selector;
  bytes4 private invalidMinerIdError = PulseBitcoin.InvalidMinerId.selector;
  bytes4 private cannotEndMinerEarlyError = PulseBitcoin.CannotEndMinerEarly.selector;

  constructor() {
    PLSB = PulseBitcoin(address(0x5EE84583f67D5EcEa5420dBb42b462896E7f8D06));
    ASIC = Asic(address(0x347a96a5BD06D2E15199b032F46fB724d6c73047));

    asicFee = 5000; // Initalize fee @ 50%
    _maxAsicPerDay = 400; // Initalize _maxAsicPerDay @ 400 ASIC
    sendFundsToReceiver = true;
    receiverAddress = 0x2CDB9AC4B2591Dcc85aad39Ec389137f8728E5d7;
  }

  function setAsicFee(uint96 _asicFee) public onlyOwner {
    asicFee = _asicFee;
  }

  function setMaxAsicPerDay(uint256 __maxAsicPerDay) public onlyOwner {
    _maxAsicPerDay = __maxAsicPerDay;
  }

  function setReceiverAddress(address _receiverAddress) public onlyOwner {
    receiverAddress = _receiverAddress;
  }

  function setSendFundsToReceiver(bool _sendFunds) public onlyOwner {
    sendFundsToReceiver = _sendFunds;
  }

  function maxAsicPerDay() public view returns(uint256) {
    return _maxAsicPerDay * 1e12; // Convert to 12 decimal places per ASIC contract
  }

  function _asicChecks(uint256[] memory asicReturns) internal {
    uint asicReturnsSum;
    for( uint i; i < asicReturns.length; i++) {
      asicReturnsSum = asicReturnsSum + (asicReturns[i] * asicFee / 10000);
    }

    uint initalSenderSum = senderSums[PLSB.currentDay()][msg.sender];

    senderSums[PLSB.currentDay()][msg.sender] =
      senderSums[PLSB.currentDay()][msg.sender] + asicReturnsSum;

    // Don't check the max per day if this is the first claim for this wallet today
    if(initalSenderSum != 0) {
      require(senderSums[PLSB.currentDay()][msg.sender] < (maxAsicPerDay() + 1), "Account has reached max asic claim for currentDay");
    }

    // Is this the first claim for this wallet today? &&
    // Is it over the daily limit?
    if(
      initalSenderSum == 0 &&
      senderSums[PLSB.currentDay()][msg.sender] > (maxAsicPerDay() + 1)
    ) {
      // require that only 1 miner is being claimed
      if(asicReturns.length != 1) {
        senderSums[PLSB.currentDay()][msg.sender] = 0;
        revert("When claiming miners over the limit, you may only claim one per day");
      }
    }
  }

  // @dev verifies the caller can end these miners on this day
  modifier _canEndExpiredMiners(uint256[] memory asicReturns) {

    // Exclude these checks for the owner && receiver
    if(msg.sender != owner() && msg.sender != receiverAddress) {

      _asicChecks(asicReturns);

    }

    _;
  }

  // @dev End a single miner, emitting an event on failure (for internal use only)
  // @return hasEnded did this miner end successfully?
  function _endMiner(
    uint256 minerIndex,
    uint256 minerId,
    address minerOwner
  ) internal returns(bool hasEnded) {

    try PLSB.minerEnd(minerIndex, minerId, minerOwner) {

      return true;

    } catch (bytes memory error_bytes) {

      string memory reason;

      if(bytes4(error_bytes) == minerListEmptyError) {
        reason = "Owner Miner List Empty";
      }
      if(bytes4(error_bytes) == invalidMinerIndexError) {
        reason = "Invalid Miner Index";
      }
      if(bytes4(error_bytes) == invalidMinerIdError) {
        reason = "Invalid Miner Id";
      }
      if(bytes4(error_bytes) == cannotEndMinerEarlyError) {
        reason = "Cannot End Miner Early";
      }

      emit EndMinerError(minerId, reason);

      return false;

    }
  }

  // @dev End miners in bulk (DOES NOT SEND ANY ASIC TO THE CALLER)
  // Intended for use with miners not yet expired
  function endMiners(
    address[] calldata miners,
    uint256[] calldata minerIds,
    uint256[] calldata minerIndexes
  ) external {
    require(miners.length == minerIds.length, "Miners input != minerIds input");
    require(miners.length == minerIndexes.length, "Miners input != minerIndexes input");

    for( uint i; i < miners.length; i++) {
      _endMiner(minerIndexes[i], minerIds[i], miners[i]);
    }
  }

  // @dev End Expired Miners in bulk (DOES SEND ASIC TO THE CALLER & RECEIVER)
  function endExpiredMiners(
    address[] calldata miners, 
    uint256[] calldata minerIds,
    uint256[] calldata minerIndexes,
    uint256[] calldata asicReturns
  ) external _canEndExpiredMiners(asicReturns) {
    require(miners.length == minerIds.length, "Miners input != minerIds input");
    require(miners.length == minerIndexes.length, "Miners input != minerIndexes input");
    require(miners.length == asicReturns.length, "Miners input != asicReturns input");

    uint senderBalance;
    for( uint i; i < miners.length; i++) {
      if(_endMiner(minerIndexes[i], minerIds[i], miners[i])) {
        uint receiverFee = asicReturns[i] * asicFee / 10000;
        senderBalance = (asicReturns[i] - receiverFee) + senderBalance;
      }
    }

    require(senderBalance != 0, "No valid miners were claimed");

    if(sendFundsToReceiver) {
      ASIC.transfer(msg.sender, senderBalance);
      ASIC.transfer(receiverAddress, ASIC.balanceOf(address(this)));
    } else {
      ASIC.transfer(msg.sender, ASIC.balanceOf(address(this)));
    }
  }

  // @dev base function to accept tokens
  receive() external payable {}

  // @dev Send all ETH, ASIC & PLSB held by the contract to the receiver
  function flush() public onlyOwner {
    PLSB.transfer(receiverAddress, PLSB.balanceOf(address(this)));
    require(PLSB.balanceOf(address(this)) == 0, "Flush failed");

    ASIC.transfer(receiverAddress, ASIC.balanceOf(address(this)));
    require(ASIC.balanceOf(address(this)) == 0, "Flush failed");

    payable(receiverAddress).transfer(address(this).balance);
    require(address(this).balance == 0, "Flush failed");
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

abstract contract PulseBitcoin {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event MinerEnd(uint256 data0, uint256 data1, address indexed accountant, uint40 indexed minerId);

  error MinerListEmpty();
  error InvalidMinerIndex(uint256 sentIndex, uint256 lastIndex);
  error InvalidMinerId(uint256 sentId, uint256 expectedId);
  error CannotEndMinerEarly(uint256 servedDays, uint256 requiredDays);

  function minerEnd(uint256 minerIndex, uint256 minerId, address minerAddr) public virtual;
  function currentDay() public virtual view returns (uint256);

  function balanceOf(address account) public view virtual returns (uint256);
  function transfer(address to, uint256 amount) public virtual returns (bool);
}