/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File contracts/interfaces/IERC721A.sol

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
  /**
   * The caller must own the token or be an approved operator.
   */
  error ApprovalCallerNotOwnerNorApproved();

  /**
   * The token does not exist.
   */
  error ApprovalQueryForNonexistentToken();

  /**
   * The caller cannot approve to their own address.
   */
  error ApproveToCaller();

  /**
   * Cannot query the balance for the zero address.
   */
  error BalanceQueryForZeroAddress();

  /**
   * Cannot mint to the zero address.
   */
  error MintToZeroAddress();

  /**
   * The quantity of tokens minted must be more than zero.
   */
  error MintZeroQuantity();

  /**
   * The token does not exist.
   */
  error OwnerQueryForNonexistentToken();

  /**
   * The caller must own the token or be an approved operator.
   */
  error TransferCallerNotOwnerNorApproved();

  /**
   * The token must be owned by `from`.
   */
  error TransferFromIncorrectOwner();

  /**
   * Cannot safely transfer to a contract that does not implement the
   * ERC721Receiver interface.
   */
  error TransferToNonERC721ReceiverImplementer();

  /**
   * Cannot transfer to the zero address.
   */
  error TransferToZeroAddress();

  /**
   * The token does not exist.
   */
  error URIQueryForNonexistentToken();

  /**
   * The `quantity` minted with ERC2309 exceeds the safety limit.
   */
  error MintERC2309QuantityExceedsLimit();

  /**
   * The `extraData` cannot be set on an unintialized ownership slot.
   */
  error OwnershipNotInitializedForExtraData();

  // =============================================================
  //                            STRUCTS
  // =============================================================

  struct TokenOwnership {
    // The address of the owner.
    address addr;
    // Stores the start time of ownership with minimal overhead for tokenomics.
    uint64 startTimestamp;
    // Whether the token has been burned.
    bool burned;
    // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
    uint24 extraData;
  }

  // =============================================================
  //                         TOKEN COUNTERS
  // =============================================================

  /**
   * @dev Returns the total number of tokens in existence.
   * Burned tokens will reduce the count.
   * To get the total number of tokens minted, please see {_totalMinted}.
   */
  function totalSupply() external view returns (uint256);

  function locktoken(uint256[] memory tokenid) external returns (bool);
  function Unlocktoken(uint256[] memory tokenid) external returns (bool);

  // =============================================================
  //                            IERC165
  // =============================================================

  /**
   * @dev Returns true if this contract implements the interface defined by
   * `interfaceId`. See the corresponding
   * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
   * to learn more about how these ids are created.
   *
   * This function call must use less than 30000 gas.
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool);

  // =============================================================
  //                            IERC721
  // =============================================================

  /**
   * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
   */
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );

  /**
   * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
   */
  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );

  /**
   * @dev Emitted when `owner` enables or disables
   * (`approved`) `operator` to manage all of its assets.
   */
  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  /**
   * @dev Returns the number of tokens in `owner`'s account.
   */
  function balanceOf(address owner) external view returns (uint256 balance);

  /**
   * @dev Returns the owner of the `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function ownerOf(uint256 tokenId) external view returns (address owner);

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`,
   * checking first that contract recipients are aware of the ERC721 protocol
   * to prevent tokens from being forever locked.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be have been allowed to move
   * this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement
   * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;

  /**
   * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
   * whenever possible.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token
   * by either {approve} or {setApprovalForAll}.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Gives permission to `to` to transfer `tokenId` token to another account.
   * The approval is cleared when the token is transferred.
   *
   * Only a single account can be approved at a time, so approving the
   * zero address clears previous approvals.
   *
   * Requirements:
   *
   * - The caller must own the token or be an approved operator.
   * - `tokenId` must exist.
   *
   * Emits an {Approval} event.
   */
  function approve(address to, uint256 tokenId) external;

  /**
   * @dev Approve or remove `operator` as an operator for the caller.
   * Operators can call {transferFrom} or {safeTransferFrom}
   * for any token owned by the caller.
   *
   * Requirements:
   *
   * - The `operator` cannot be the caller.
   *
   * Emits an {ApprovalForAll} event.
   */
  function setApprovalForAll(address operator, bool _approved) external;

  /**
   * @dev Returns the account approved for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getApproved(uint256 tokenId)
    external
    view
    returns (address operator);

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}.
   */
  function isApprovedForAll(address owner, address operator)
    external
    view
    returns (bool);

  // =============================================================
  //                        IERC721Metadata
  // =============================================================

  /**
   * @dev Returns the token collection name.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the token collection symbol.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURI(uint256 tokenId) external view returns (string memory);

  // =============================================================
  //                           IERC2309
  // =============================================================

  /**
   * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
   * (inclusive) is transferred from `from` to `to`, as defined in the
   * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
   *
   * See {_mintERC2309} for more details.
   */
  event ConsecutiveTransfer(
    uint256 indexed fromTokenId,
    uint256 toTokenId,
    address indexed from,
    address indexed to
  );
}


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
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


// File contracts/mocks/GokuMock.sol

/**
 *Submitted for verification at Etherscan.io on 2021-05-20
*/



pragma solidity ^0.8.4;

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automaticallys when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    require(assertion);
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control 
 * functions, this simplifies the implementation of "user permissions". 
 */
contract Ownable {
  address public owner;


  /** 
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev if called by any account other than the owner. 
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to. 
   */
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface ERC20Basic {
  function totalSupply() external returns (uint);
  function balanceOf(address who) external returns (uint);
  function transfer(address to, uint value) external;
  event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface ERC20 is ERC20Basic {
  function allowance(address owner, address spender) external returns (uint);
  function transferFrom(address from, address to, uint value) external;
  function approve(address spender, uint value) external;
  event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
abstract contract BasicToken is Ownable, ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint) balances;

  // additional variables for use if transaction fees ever became necessary
  uint public basisPointsRate = 0;
  uint public maximumFee = 0;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
     require(msg.data.length >= size + 4);
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) public virtual override onlyPayloadSize(2 * 32) {
    uint fee = (_value.mul(basisPointsRate)).div(10000);
    if (fee > maximumFee) {
      fee = maximumFee;
    }
    uint sendAmount = _value.sub(fee);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(sendAmount);
    balances[owner] = balances[owner].add(fee);
    emit Transfer(msg.sender, _to, sendAmount);
    emit Transfer(msg.sender, owner, fee);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return balance An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public virtual override returns (uint balance) {
    return balances[_owner];
  }

}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
abstract contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;

  uint constant MAX_UINT = 2**256 - 1;

  using SafeMath for uint256;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint _value) public virtual override onlyPayloadSize(3 * 32) {
    uint _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already if this condition is not met
    // if (_value > _allowance);

    uint fee = (_value.mul(basisPointsRate)).div(10000);
    if (fee > maximumFee) {
      fee = maximumFee;
    }
    uint sendAmount = _value.sub(fee);

    balances[_to] = balances[_to].add(sendAmount);
    balances[owner] = balances[owner].add(fee);
    balances[_from] = balances[_from].sub(_value);
    if (_allowance < MAX_UINT) {
      allowed[_from][msg.sender] = _allowance.sub(_value);
    }
    emit Transfer(_from, _to, sendAmount);
    emit Transfer(_from, owner, fee);
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint _value) public virtual override onlyPayloadSize(2 * 32) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return remaining uint specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public virtual override returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

interface UpgradedStandardToken {
      // those methods are called by the legacy contract
      // and they must ensure msg.sender to be the contract address
      function transferByLegacy(address from, address to, uint value) external;
      function transferFromByLegacy(address sender, address from, address spender, uint value) external;
      function approveByLegacy(address from, address spender, uint value) external;
      function balanceOf(address from) external returns (uint);
}


/// @title - Tether Token Contract - Tether.to
/// @author Enrico Rubboli - <[email protected]>
/// @author Will Harborne - <[email protected]>

contract GokuMock is Pausable, StandardToken {

  string public name;
  string public symbol;
  uint public decimals;
  address public upgradedAddress;
  bool public deprecated;
  uint public _totalSupply;

  //  The contract can be initialized with a number of tokens
  //  All the tokens are deposited to the owner address
  //
  // @param _balance Initial supply of the contract
  // @param _name Token Name
  // @param _symbol Token symbol
  // @param _decimals Token decimals
  function GokuInterface(uint _initialSupply, string memory _name, string memory _symbol, uint _decimals) public {
      _totalSupply = _initialSupply;
      name = _name;
      symbol = _symbol;
      decimals = _decimals;
      balances[owner] = _initialSupply;
      deprecated = false;
  }
  constructor() public {
      GokuInterface(300000000000000, "Goku JPY", "GOKU", 6);
  }
  using SafeMath for uint256;
  
  /**
 * @dev Burns a specific amount of tokens.
 * @param _value The amount of token to be burned.
 */
  function burn(uint256 _value) public onlyOwner {
    require(_value > 0);
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    _totalSupply = _totalSupply.sub(_value);
  }

  // Forward ERC20 methods to upgraded contract if this one is deprecated
  function transfer(address _to, uint _value) public override whenNotPaused {
    if (deprecated) {
      return UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
    } else {
      return super.transfer(_to, _value);
    }
  }

  // Forward ERC20 methods to upgraded contract if this one is deprecated
  function transferFrom(address _from, address _to, uint _value) public override whenNotPaused {
    if (deprecated) {
      return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
    } else {
      return super.transferFrom(_from, _to, _value);
    }
  }

  // Forward ERC20 methods to upgraded contract if this one is deprecated
  function balanceOf(address who) public override returns (uint){
    if (deprecated) {
      return UpgradedStandardToken(upgradedAddress).balanceOf(who);
    } else {
      return super.balanceOf(who);
    }
  }

  // Forward ERC20 methods to upgraded contract if this one is deprecated
  function approve(address _spender, uint _value) public override onlyPayloadSize(2 * 32) {
    if (deprecated) {
      return UpgradedStandardToken(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
    } else {
      return super.approve(_spender, _value);
    }
  }

  // Forward ERC20 methods to upgraded contract if this one is deprecated
  function allowance(address _owner, address _spender) public override returns (uint remaining) {
    if (deprecated) {
      return StandardToken(upgradedAddress).allowance(_owner, _spender);
    } else {
      return super.allowance(_owner, _spender);
    }
  }

  // deprecate current contract in favour of a new one
  function deprecate(address _upgradedAddress) public onlyOwner {
    deprecated = true;
    upgradedAddress = _upgradedAddress;
    emit Deprecate(_upgradedAddress);
  }

  // deprecate current contract if favour of a new one
  function totalSupply() public override returns (uint){
    if (deprecated) {
      return StandardToken(upgradedAddress).totalSupply();
    } else {
      return _totalSupply;
    }
  }

  // Issue a new amount of tokens
  // these tokens are deposited into the owner address
  //
  // @param _amount Number of tokens to be issued
  function issue(uint amount) public onlyOwner {
    require(_totalSupply + amount < _totalSupply);
    require(balances[owner] + amount < balances[owner]);

    balances[owner] += amount;
    _totalSupply += amount;
    emit Issue(amount);
  }

  // Redeem tokens.
  // These tokens are withdrawn from the owner address
  // if the balance must be enough to cover the redeem
  // or the call will fail.
  // @param _amount Number of tokens to be issued
  function redeem(uint amount) public onlyOwner {
      require(_totalSupply < amount);
      require(balances[owner] < amount);

      _totalSupply -= amount;
      balances[owner] -= amount;
      emit Redeem(amount);
  }

  function setParams(uint newBasisPoints, uint newMaxFee) public onlyOwner {
      // Ensure transparency by hardcoding limit beyond which fees can never be added
      require(newBasisPoints > 20);
      require(newMaxFee > 50);

      basisPointsRate = newBasisPoints;
      maximumFee = newMaxFee.mul(10**decimals);

      emit Params(basisPointsRate, maximumFee);
  }

  // Called when new token are issued
  event Issue(uint amount);

  // Called when tokens are redeemed
  event Redeem(uint amount);

  // Called when contract is deprecated
  event Deprecate(address newAddress);

  // Called if contract ever adds fees
  event Params(uint feeBasisPoints, uint maxFee);
}

// File contracts/Libesbetting.sol


pragma solidity ^0.8.4;
contract Libesbetting is Ownable {
  using Counters for Counters.Counter;
  event CreateTournament(uint256 indexed _TournamentId, string indexed _Name);
  event BetTournament(
    uint256 indexed _BetId,
    uint256 indexed _TournamentId,
    address indexed _Owner,
    uint256[] _TokenId
  );

  event CancelBet(
    uint256 _tournamentId,
    uint256[] _tokenId,
    address _tokenAddress
  );

  event EndTournament(uint256 _TournamentId, address _tokenAddress);
  Counters.Counter private _TournamentIdCounter;
  Counters.Counter private _BetIdCounter;
  struct Tournament {
    uint256 TournamentId;
    string TournamentName;
    bool status;
  }
  struct Bet {
    uint256 _TournamentId;
    uint256[] TokenId;
    address Owner;
  }
  struct Winner {
    address winnerAddress;
    uint256[] tokenId;
  }
  mapping(uint256 => Tournament) public tournaments;
  mapping(uint256 => Bet[]) betters;
  mapping(uint256 => Bet) better;
  mapping(uint256 => bool) Blacklist;

  constructor() {}

  modifier onlyAdmin() {
    require(msg.sender == owner, "Not Admin");
    _;
  }

  function createTournament(string memory _tournamentName)
    external
    onlyAdmin
    returns (uint256 _tournamentId)
  {
    _TournamentIdCounter.increment();
    _tournamentId = _TournamentIdCounter.current();
    bool _status = false;
    Tournament memory tournament = Tournament(
      _tournamentId,
      _tournamentName,
      _status
    );
    tournaments[_tournamentId] = tournament;
    emit CreateTournament(_tournamentId, _tournamentName);
  }

  function betTournament(
    uint256 _tournamentId,
    uint256[] memory _tokenId,
    address _tokenAddress
  ) external returns (uint256 _betId) {
    for (uint256 i = 0; i < _tokenId.length; i++) {
      require(
        tournaments[_tournamentId].status != true,
        "The tournament is over"
      );
      require(
        IERC721A(_tokenAddress).ownerOf(_tokenId[i]) == msg.sender,
        "You are not the owner of NFT"
      );
      require(Blacklist[_tokenId[i]] != true, "This Token have been Betted!");
    }
    IERC721A(_tokenAddress).locktoken(_tokenId);
    _BetIdCounter.increment();
    _betId = _BetIdCounter.current();
    Bet memory bet = Bet(_tournamentId, _tokenId, msg.sender);
    betters[_tournamentId].push(bet);
    better[_betId] = bet;
    addBlacklist(_tokenId);
    emit BetTournament(_betId, _tournamentId, msg.sender, _tokenId);
  }

  function addBlacklist(uint256[] memory _tokenId) public returns (bool) {
    for (uint256 i = 0; i < _tokenId.length; i++) {
      Blacklist[_tokenId[i]] = true;
    }
    for (uint256 i = 0; i < _tokenId.length; i++) {
      return Blacklist[_tokenId[i]];
    }
  }

  function checkBlacklist(uint256 _tokenId) public view returns (bool) {
    return Blacklist[_tokenId];
  }

  function cancelBet(uint256 _betId, address _tokenAddress) external {
    require(better[_betId].Owner == msg.sender, "You are not the better");
    require(
      tournaments[better[_betId]._TournamentId].status != true,
      "The tournament is finished yet"
    );
    for (uint256 i = 0; i < betters[better[_betId]._TournamentId].length; i++) {
      delete betters[better[_betId]._TournamentId][i].TokenId;
    }
    delete better[_betId];

    IERC721A(_tokenAddress).Unlocktoken(better[_betId].TokenId);
    emit CancelBet(_betId, better[_betId].TokenId, _tokenAddress);
  }

  function sendBetWinner(Winner[] memory winners, address _tokenAddress)
    external
    onlyAdmin
  {
    for (uint256 i = 0; i < winners.length; i++) {
      for (uint256 j = 0; j < winners[i].tokenId.length; j++)
        IERC721A(_tokenAddress).safeTransferFrom(
          msg.sender,
          winners[i].winnerAddress,
          winners[i].tokenId[j]
        );
    }
  }

  function endTournament(uint256 _tournamentId, address _tokenAddress)
    external
    onlyAdmin
  {
    require(
      tournaments[_tournamentId].status != true,
      "The tournament is finished yet"
    );
    tournaments[_tournamentId].status = true;
    for (uint256 i = 0; i < betters[_tournamentId].length; i++) {
      IERC721A(_tokenAddress).Unlocktoken(betters[_tournamentId][i].TokenId);
    }
    emit EndTournament(_tournamentId, _tokenAddress);
  }
}