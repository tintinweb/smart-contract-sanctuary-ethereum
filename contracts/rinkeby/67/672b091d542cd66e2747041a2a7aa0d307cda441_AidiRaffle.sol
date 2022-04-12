/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

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

/**
 * @title AidiWithdrawable
 * @dev Supports being able to get tokens or ETH out of a contract with ease
 */
contract AidiWithdrawable is Ownable {
  function withdrawTokens(address _tokenAddress, uint256 _amount) external onlyOwner {
    IERC20 _token = IERC20(_tokenAddress);
    _amount = _amount > 0 ? _amount : _token.balanceOf(address(this));
    require(_amount > 0, "Nothing to withdraw");
    _token.transfer(owner(), _amount);
  }

  function withdrawETH() external onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
  }
}

/**
 * @title AidiRaffle
 * @dev This is the main contract that supports lotteries and raffles.
 */
contract AidiRaffle is AidiWithdrawable {
  struct Raffle {
    address owner;
    address entryToken; // Raffle entry ERC20 token
    uint256 entryFee; // Raffle entry fees amount for one entry, 0 if there is no entry fee
    uint256 minEntriesForDraw; // Minimum number of entries required to conduct the raffle draw (0 means no minimum)
    uint256 maxEntriesForRaffle; // 0 means unlimited entries
    uint256 maxEntriesPerAddress; // 0 means unlimited entries
    address[] entries;
    uint256 entryFeesCollected; // Total collected entry fees
    uint256 totalRewardPercentage;// Percentage of collected entry fees that is split among winners
    uint256 start; // timestamp (uint256) of start time (0 if start when raffle is created)
    uint256 end; // timestamp (uint256) of end time (0 if can be entered until owner draws)
    uint256 numberOfwinners;
    address[] winners;
    bool isComplete;
    bool isClosed;
  }

  uint8 public aidiUtilityFee = 2;
  mapping(bytes32 => Raffle) public raffles;
  bytes32[] public raffleIds;
  mapping(bytes32 => mapping(address => uint256)) public entriesIndexed;
  mapping(bytes32 => address[]) private uniqueAddressEntries;
  mapping(bytes32 => mapping(address => bool)) public isUniqueAddressAdded;  

  event CreateRaffle(address indexed creator, bytes32 id);
  event EnterRaffle(
    bytes32 indexed id,
    address raffler,
    uint256 numberOfEntries
  );
  event DrawWinners(bytes32 indexed id, address[] winners, uint256 amount);
  event CloseRaffle(bytes32 indexed id);

  function getAllRaffles() external view returns (bytes32[] memory) {
    return raffleIds;
  }

  function getRaffleEntries(bytes32 _id)
    external
    view
    returns (address[] memory)
  {
    return raffles[_id].entries;
  }

  function getTotalNumOfRaffles()
    external
    view
    returns (uint256)
  {
    return raffleIds.length;
  }

  function getRaffleAtIndex(uint256 _index)
    external
    view
    returns (bytes32)
  {
    return raffleIds[_index];
  }

  function getTotalEntryFeesCollected(bytes32 _id)
    external
    view
    returns (uint256)
  {
    return raffles[_id].entryFeesCollected;
  }

  function getTotalPrizeForRaffle(bytes32 _id)
    external
    view
    returns (uint256)
  {
    uint256 _totalPrizeToSendWinners =  (raffles[_id].entryFeesCollected * raffles[_id].totalRewardPercentage) / 100;
    return _totalPrizeToSendWinners ;
  }

  function getPrizeForSingleWinnerInRaffle(bytes32 _id)
    external
    view
    returns (uint256)
  {
    uint256 _totalPrizeToSendWinners =  (raffles[_id].entryFeesCollected * raffles[_id].totalRewardPercentage) / 100;
    if(raffles[_id].numberOfwinners>0)
    {
        return (_totalPrizeToSendWinners/ raffles[_id].numberOfwinners);
    }
    return 0;
  }

  function isUserOwnerOrPartcipating(bytes32 _id, address userAddress)
    external
    view
    returns (uint256)
  {
    uint256 returnVal = 0; //not participating returns 0
    
    if(userAddress == raffles[_id].owner) //If Creator returns 2
    {
     returnVal = 2;
    }
    address[] memory addresses = uniqueAddressEntries[_id];
    for(uint256 i = 0; i < addresses.length; i++) {
      if(userAddress == addresses[i]) //If Participant and owner returns 3. If only participating, returns 1
      {
        returnVal +=1;
        break;
      }
    }
   
    return returnVal; 
  }


  function isRaffleDrawn(bytes32 _id)
    external
    view
    returns (bool)
  {
    return raffles[_id].isComplete;
  }

  function isRaffleClosed(bytes32 _id)
    external
    view
    returns (bool)
  {
    return raffles[_id].isComplete;
  }

  function getNumberOfWinnersForRaffle(bytes32 _id)
    external
    view
    returns (uint256)
  {
    return raffles[_id].numberOfwinners;
  }

  function getRaffleWinners(bytes32 _id)
    external
    view
    returns (address[] memory)
  {
    return raffles[_id].winners;
  }

  function getNameOfEntryTokenForRaffle(bytes32 _id)
    external
    view
    returns (string memory)
  {
      IERC20Metadata _entryToken = IERC20Metadata(raffles[_id].entryToken);
      return _entryToken.name();
  }

  function getEntryTokenForRaffle(bytes32 _id)
    external
    view
    returns (address)
  {
      return raffles[_id].entryToken;
  }

  function getMinEntriesForDraw(bytes32 _id)
    external
    view
    returns (uint256)
  {
    return raffles[_id].minEntriesForDraw;
  }

  function getMaxEntriesForRaffle(bytes32 _id)
    external
    view
    returns (uint256)
  {
    return raffles[_id].maxEntriesForRaffle;
  }

  function getMaxEntriesPerAddressForRaffle(bytes32 _id)
    external
    view
    returns (uint256)
  {
    return raffles[_id].maxEntriesPerAddress;
  }

  function getEntryPriceForRaffle(bytes32 _id)
    external
    view
    returns (uint256)
  {
    return raffles[_id].entryFee;
  }

  function getUniqueAddressesLengthInRaffle(bytes32 _id)
    external
    view
    returns (uint256)
  {
    return uniqueAddressEntries[_id].length;
  }

  function getUniqueAddressesInRaffle(bytes32 _id)
    external
    view
    returns (address[] memory)
  {
    return uniqueAddressEntries[_id];
  }


// Creating Rafflee 
  function createRaffle(
    address _entryToken,
    uint256 _entryFee,
    uint256 _minEntriesForDraw,
    uint256 _maxEntriesForRaffle,
    uint256 _maxEntriesPerAddress,
    uint256 _totalRewardPercentage,
    uint256 _start,
    uint256 _end,
    uint256 _numberOfwinners
  ) external payable {

    _validateDates(_start, _end);
    require(_numberOfwinners > 0, "There should be at least one winner!");
    require(_totalRewardPercentage >= 0 && _totalRewardPercentage < (100 - aidiUtilityFee), "Should be between 0 and (100 - aidiUtilityFee).");
    require(_maxEntriesPerAddress <= _maxEntriesForRaffle, "Max entries per address should be lesser than or equal to max entries per raffle!");
    require(_minEntriesForDraw <= _maxEntriesForRaffle, "Min entries for draw should be lesser than or equal to max entries per raffle!");

    bytes32 _id = sha256(abi.encodePacked(msg.sender, block.number));
    address[] memory _entries;
    address[] memory _winners;

    raffles[_id] = Raffle({
    owner: msg.sender,
    entryToken: _entryToken,
    entryFee: _entryFee,
    minEntriesForDraw: _minEntriesForDraw,
    maxEntriesForRaffle: _maxEntriesForRaffle,
    maxEntriesPerAddress: _maxEntriesPerAddress,
    entries: _entries,
    entryFeesCollected: 0,
    totalRewardPercentage: _totalRewardPercentage,
    start: _start,
    end: _end,
    numberOfwinners: _numberOfwinners,
    winners: _winners,
    isComplete: false,
    isClosed: false
    });
    raffleIds.push(_id);
    emit CreateRaffle(msg.sender, _id);
  }

  function drawWinners(bytes32 _id) external {
    Raffle storage _raffle = raffles[_id];
    require(!_raffle.isComplete, "Raffle has already been drawn and completed.");
    require((_raffle.entries.length >= _raffle.minEntriesForDraw)||(_raffle.end == 0 || block.timestamp > _raffle.end), "Raffle's minimum entry requirement for drawing not met or the raffle entry period is not over yet.");

    if (_raffle.entryFeesCollected > 0) {
        IERC20 _entryToken = IERC20(_raffle.entryToken);

        uint256 _feeAidi = (_raffle.entryFeesCollected * aidiUtilityFee) / 100;
        uint256 _totalPrizeToSendWinners =  (_raffle.entryFeesCollected * _raffle.totalRewardPercentage) / 100;
        uint256 _feesToSendRaffleOwner = _raffle.entryFeesCollected - _totalPrizeToSendWinners - _feeAidi;
        uint256 _prizePerEachWinner = (_totalPrizeToSendWinners/_raffle.numberOfwinners);

        if (_feeAidi > 0) {
            _entryToken.transfer(owner(), _feeAidi);
        }
        if (_feesToSendRaffleOwner > 0) {
            _entryToken.transfer(_raffle.owner, _feesToSendRaffleOwner);
        }

        if (_prizePerEachWinner > 0) {
                for(uint256 i = 0; i < _raffle.numberOfwinners; i++) {
                    uint256 _winnerIdx = _random(_raffle.entries.length) %
                    _raffle.entries.length;
                    address _winner = _raffle.entries[_winnerIdx];
                    _raffle.winners[i] = _winner;
                    _entryToken.transfer(_winner, _prizePerEachWinner);
                }
        }
        emit DrawWinners(_id, _raffle.winners, _prizePerEachWinner);
    }else{
        emit DrawWinners(_id, _raffle.winners, 0);
    }
    _raffle.isComplete = true;
  }

  function closeRaffleAndRefund(bytes32 _id) external {
    Raffle storage _raffle = raffles[_id];
    require(_raffle.owner == msg.sender, "Must be the raffle owner to close the raffle.");
    require(!_raffle.isComplete, "Raffle cannot be closed if it is completed already.");

    IERC20 _entryToken = IERC20(_raffle.entryToken);
    for (uint256 _i = 0; _i < _raffle.entries.length; _i++) {
      address _user = _raffle.entries[_i];
      _entryToken.transfer(_user, _raffle.entryFee);
    }

    _raffle.isComplete = true;
    _raffle.isClosed = true;
    emit CloseRaffle(_id);
  }

  function enterRaffle(bytes32 _id, uint256 _numEntries) external {
    Raffle storage _raffle = raffles[_id];
    require(_raffle.owner != address(0), "We do not recognize this raffle.");
    require(_raffle.start <= block.timestamp, "Raffle is not started yet!");
    require(_raffle.end == 0 || _raffle.end >= block.timestamp, "Sorry, this raffle has ended.");
    require(_numEntries > 0 &&(_raffle.maxEntriesPerAddress == 0 || entriesIndexed[_id][msg.sender] + _numEntries <= _raffle.maxEntriesPerAddress),
    "You have purchased maximum entries.");
    require(!_raffle.isComplete, "Sorry, this raffle has closed entries.");
    require((_raffle.entries.length + _numEntries) <= _raffle.maxEntriesForRaffle, "Sorry, the max entries for this raffle has reached.");

    if (_raffle.entryFee > 0) {
      IERC20 _entryToken = IERC20(_raffle.entryToken);
      _entryToken.transferFrom(
        msg.sender,
        address(this),
        _raffle.entryFee * _numEntries
      );
      _raffle.entryFeesCollected += _raffle.entryFee * _numEntries;
    }

    for (uint256 _i = 0; _i < _numEntries; _i++) {
      _raffle.entries.push(msg.sender);
    }
    entriesIndexed[_id][msg.sender] += _numEntries;
    addUniqueAddressInRaffle( _id, msg.sender);
    emit EnterRaffle(_id, msg.sender, _numEntries);
  }

  function addUniqueAddressInRaffle(bytes32 _id, address account) private {
    if (!isUniqueAddressAdded[_id][account])
    {
        isUniqueAddressAdded[_id][account] = true;
        uniqueAddressEntries[_id].push(account);
    }
   }

  function changeRaffleOwner(bytes32 _id, address _newOwner) external {
    Raffle storage _raffle = raffles[_id];
    require(_raffle.owner == msg.sender, "Must be the raffle owner to change owner.");
    require(!_raffle.isComplete, "Raffle has already been drawn and completed.");

    _raffle.owner = _newOwner;
  }

  function changeEndDate(bytes32 _id, uint256 _newEnd) external {
    Raffle storage _raffle = raffles[_id];
    require(_raffle.owner == msg.sender, "Must be the raffle owner to change owner.");
    require(!_raffle.isComplete, "Raffle has already been drawn and completed.");
    _raffle.end = _newEnd;
  }

  function changeAidiUtilityFee(uint8 _newPercentage) external onlyOwner {
    require(_newPercentage >= 0 && _newPercentage < 100, "Should be between 0 and 100.");
    aidiUtilityFee = _newPercentage;
  }

  function _validateDates(uint256 _start, uint256 _end) private view {
    require(_start == 0 || _start >= block.timestamp, "Start time should be 0 or after the current time");
    require(_end == 0 || _end > block.timestamp, "End time should be 0 or after the current time");
    if (_start > 0) {
      if (_end > 0) {
        require(_start < _end, "Start time must be before the end time");
      }
    }
  }

  function _random(uint256 _entries) private view returns (uint256) {
    return
      uint256(
        keccak256(abi.encodePacked(block.difficulty, block.timestamp, _entries))
      );
  }
}