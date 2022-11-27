pragma solidity 0.7.4;

import "@horizongames/skyweaver-contracts/contracts/factories/RewardFactory.sol";

contract SilverRewardFactory is RewardFactory {
  constructor(
    address _initialOwner,
    address _assetsAddr,
    uint256 _periodLength,
    uint256 _periodMintLimit,
    bool _whitelistOnly
  ) RewardFactory(_initialOwner, _assetsAddr, _periodLength, _periodMintLimit, _whitelistOnly) public {}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

/**
 * @dev ERC-1155 interface for accepting safe transfers.
 */
interface IERC1155TokenReceiver {

  /**
   * @notice Handle the receipt of a single ERC1155 token type
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value MUST result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _id        The id of the token being transferred
   * @param _amount    The amount of tokens being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);

  /**
   * @notice Handle the receipt of multiple ERC1155 token types
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value WILL result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeBatchTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _ids       An array containing ids of each token being transferred
   * @param _amounts   An array containing amounts of each token being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;


/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {

    /**
     * @notice Query if a contract implements an interface
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas
     * @param _interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity 0.7.4;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {

  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath#mul: OVERFLOW");

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath#sub: UNDERFLOW");
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath#add: OVERFLOW");

    return c; 
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
    return a % b;
  }
}

pragma solidity 0.7.4;

import "@0xsequence/erc-1155/contracts/interfaces/IERC20.sol";
import "@0xsequence/erc-1155/contracts/utils/SafeMath.sol";


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://eips.ethereum.org/EIPS/eip-20
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  /**
    * @dev Total number of tokens in existence
    */
  function totalSupply() public override view returns (uint256) {
    return _totalSupply;
  }

  /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return A uint256 representing the amount owned by the passed address.
    */
  function balanceOf(address owner) public override view returns (uint256) {
    return _balances[owner];
  }

  /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param owner address The address which owns the funds.
    * @param spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
  function allowance(address owner, address spender) public override view returns (uint256) {
    return _allowed[owner][spender];
  }

  /**
    * @dev Transfer token to a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
  function transfer(address to, uint256 value) public override returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param spender The address which will spend the funds.
    * @param value The amount of tokens to be spent.
    */
  function approve(address spender, uint256 value) public override returns (bool) {
    _approve(msg.sender, spender, value);
    return true;
  }

  /**
    * @dev Transfer tokens from one address to another.
    * Note that while this function emits an Approval event, this is not required as per the specification,
    * and other compliant implementations may not emit the event.
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256 the amount of tokens to be transferred
    */
  function transferFrom(address from, address to, uint256 value) public override returns (bool) {
    _transfer(from, to, value);
    _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
    return true;
  }

  /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    * approve should be called when _allowed[msg.sender][spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * Emits an Approval event.
    * @param spender The address which will spend the funds.
    * @param addedValue The amount of tokens to increase the allowance by.
    */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
    return true;
  }

  /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * Emits an Approval event.
    * @param spender The address which will spend the funds.
    * @param subtractedValue The amount of tokens to decrease the allowance by.
    */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
    return true;
  }

  /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
  function _transfer(address from, address to, uint256 value) internal {
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  /**
    * @dev Internal function that mints an amount of the token and assigns it to
    * an account. This encapsulates the modification of balances such that the
    * proper events are emitted.
    * @param account The account that will receive the created tokens.
    * @param value The amount that will be created.
    */
  function _mint(address account, uint256 value) internal {
    require(account != address(0));

    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

  /**
    * @dev Internal function that burns an amount of the token of a given
    * account.
    * @param account The account whose tokens will be burnt.
    * @param value The amount that will be burnt.
    */
  function _burn(address account, uint256 value) internal {
    require(account != address(0));

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /**
    * @dev Approve an address to spend another addresses' tokens.
    * @param owner The address that owns the tokens.
    * @param spender The address that will spend the tokens.
    * @param value The number of tokens that can be spent.
    */
  function _approve(address owner, address spender, uint256 value) internal {
    require(spender != address(0));
    require(owner != address(0));

    _allowed[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  /**
    * @dev Internal function that burns an amount of the token of a given
    * account, deducting from the sender's allowance for said account. Uses the
    * internal burn function.
    * Emits an Approval event (reflecting the reduced allowance).
    * @param account The account whose tokens will be burnt.
    * @param value The amount that will be burnt.
    */
  function _burnFrom(address account, uint256 value) internal {
    _burn(account, value);
    _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
  }

}

contract ERC20Mock is ERC20 {
  constructor() public { }

  function mockMint(address _address, uint256 _amount) public {
    _mint(_address, _amount);
  }

}

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "../utils/TieredOwnable.sol";
import "../interfaces/ISkyweaverAssets.sol";
import "@0xsequence/erc-1155/contracts/utils/SafeMath.sol"; 
import "@0xsequence/erc-1155/contracts/interfaces/IERC165.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC20.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC1155TokenReceiver.sol";

/**
 * @notice Allows players mint items in exchange for burning items and some USDC
 *         Minting logic supports bonding curve for USDC.
 */
contract BondingCurveFactory is IERC1155TokenReceiver, TieredOwnable {
  using SafeMath for uint256;
  
  /***********************************|
  |             Variables             |
  |__________________________________*/

  // Assets
  IERC20 immutable public usdc;                      // USDC contract address
  ISkyweaverAssets immutable public skyweaverAssets; // ERC-1155 Skyweaver items contract
  uint256  immutable internal itemRangeMin;          // Lower bound for the range of items IDs that can be used to mint
  uint256 immutable internal itemRangeMax;           // Upper bound for the range of items IDs that can be used to mint

  // Amount of items needed to be burnt per mint
  uint256 internal immutable COST_IN_ITEMS;

  // Minting curve parameters
  // Curve is (x + USDC_CURVE_CONSTANT)^2 / USDC_CURVE_SCALE_DOWN
  uint256 internal immutable USDC_CURVE_CONSTANT;   // Starting X value on the curve
  uint256 internal immutable USDC_CURVE_SCALE_DOWN; // Multiplier we use as denominator for the curve
  uint256 internal immutable USDC_CURVE_TICK_SIZE;  // Supply amount after which price increases

  // Mapping for tracking supplies
  mapping (uint256 => uint256) public mintedAmounts; // Tracks number of items minted by this contract

  // Payment payload on erc-1155 transfer
  struct MintTokenRequest {
    address recipient;            // Who receives the tokens
    uint256[] itemsBoughtIDs;     // Token IDs to buy
    uint256[] itemsBoughtAmounts; // Amount of token to buy for each ID
    uint256 maxUSDC;              // Maximum amount of USDC to use for the order
  }

  /***********************************|
  |            Constructor            |
  |__________________________________*/

  /**
   * @notice Create factory, link skyweaver items and store initial parameters
   * @param _firstOwner             Address of the first owner
   * @param _usdc                   The address of the USDC contract
   * @param _skyweaverAssetsAddress The address of the Skyweaver ERC-1155 contract
   * @param _itemRangeMin           Minimum id for silver cards
   * @param _itemRangeMax           Maximum id for silver cards
   * @param _costInItems            Amount of items needed to burn per mint
   * @param _usdcCurveConstant      Starting X value on the curve
   * @param _usdcCurveScaleDown     Multiplier we use as denominator for the curve
   * @param _usdcCurveTickSize      Supply amount after which price increases
   */
  constructor(
    address _firstOwner,
    uint256 _usdc,
    address _skyweaverAssetsAddress,
    uint256 _itemRangeMin,
    uint256 _itemRangeMax,
    uint256 _costInItems,
    uint256 _usdcCurveConstant,
    uint256 _usdcCurveScaleDown,
    uint256 _usdcCurveTickSize
  ) TieredOwnable(_firstOwner) 
  {
    require(
      _skyweaverAssetsAddress != address(0) && 
      _itemRangeMin < _itemRangeMax,
      "BondingCurveFactory#constructor: INVALID_INPUT"
    );

    // Assets
    usdc = IERC20(_usdc);
    skyweaverAssets = ISkyweaverAssets(_skyweaverAssetsAddress);
    itemRangeMin = _itemRangeMin;
    itemRangeMax = _itemRangeMax;

    // Parameters
    COST_IN_ITEMS = _costInItems;
    USDC_CURVE_CONSTANT = _usdcCurveConstant;    // e.g. 35 * 100
    USDC_CURVE_SCALE_DOWN = _usdcCurveScaleDown; // e.g. 100
    USDC_CURVE_TICK_SIZE = _usdcCurveTickSize;   // e.g. 10 * 100 for increase every 10 mints
  }

  
  /***********************************|
  |      Receiver Method Handler      |
  |__________________________________*/

  /**
   * @notice Prevents receiving Ether or calls to unsuported methods
   */
  fallback () external {
    revert("BondingCurveFactory#_: UNSUPPORTED_METHOD");
  }

  /**
   * @notice Players converting silver cards to conquest entries
   * @dev Payload is passed to and verified by onERC1155BatchReceived()
   */
  function onERC1155Received(
    address _operator,
    address _from,
    uint256 _id, 
    uint256 _amount, 
    bytes calldata _data
  )
    external override returns(bytes4)
  {
    // Convert payload to arrays to pass to onERC1155BatchReceived()
    uint256[] memory ids = new uint256[](1);
    uint256[] memory amounts = new uint256[](1);
    ids[0] = _id;
    amounts[0] = _amount;

    // Will revert call if doesn't pass
    onERC1155BatchReceived(_operator, _from, ids, amounts, _data);
    
    // Return success
    return IERC1155TokenReceiver.onERC1155Received.selector;
  }

  /**
   * @notice Players sending assets to mint
   * @param _ids     An array containing ids of each Token being transferred
   * @param _amounts An array containing amounts of each Token being transferred
   * @param _data    If data is provided, it should be address who will receive the entries
   */
  function onERC1155BatchReceived(
    address, // _operator
    address  _from,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  )
    public override returns(bytes4)
  { 
    require(
      msg.sender == address(skyweaverAssets), 
      "BondingCurveFactory#onERC1155BatchReceived: INVALID_TOKEN_ADDRESS"
    );

    // Decode MintTokenRequest from _data to call _mint()
    MintTokenRequest memory req;
    req = abi.decode(_data, (MintTokenRequest));

    // Calculate cost
    (uint256 costItems, uint256 costUSDC) = getMintingTotalCost(req.itemsBoughtIDs, req.itemsBoughtAmounts);

    // Calculate # of items sent
    uint256 nItemsReceived = _paidItemAmount(_ids, _amounts);

    // Validate payment is sufficient
    require(nItemsReceived == costItems, "BondingCurveFactory#onERC1155BatchReceived: INCORRECT NUMBER OF ITEMS SENT");
    require(costUSDC <= req.maxUSDC, "BondingCurveFactory#onERC1155BatchReceived: MAX USDC EXCEEDED");

    // Transfer USDC to here
    usdc.transferFrom(_from, address(this), costUSDC);

    // Burn items received
    skyweaverAssets.batchBurn(_ids, _amounts);

    // Increase supplies and insure there are no duplicated IDs
    uint256 previousID = 0; // Can't mint id 0, so we use it as first ID
    for (uint256 i = 0; i < req.itemsBoughtIDs.length; i++) {
      uint256 id = req.itemsBoughtIDs[i];
      require(id != 0 && id > previousID, "BondingCurveFactory#onERC1155BatchReceived: UNSORTED itemsBoughtIDs ARRAY OR CONTAIN DUPLICATES");
      mintedAmounts[id] = mintedAmounts[id].add(req.itemsBoughtAmounts[i]);
      previousID = id;
    }

    // Minting assets 
    address recipient = req.recipient == address(0x0) ? _from : req.recipient;
    skyweaverAssets.batchMint(recipient, req.itemsBoughtIDs, req.itemsBoughtAmounts, "");

    // Return success
    return IERC1155TokenReceiver.onERC1155BatchReceived.selector;
  }


  /***********************************|
  |             Payments              |
  |__________________________________*/  

  /**
   * @notice Calculate amount of items sent by user
   * @param _ids      Ids of items sent by user
   * @param _amounts  Amount of each item sent by user
   */
  function _paidItemAmount(uint256[] memory _ids, uint256[] memory _amounts) view internal returns (uint256 nItems) {
    nItems = 0; // Number of valid Items sent

    // Count how many valid items were sent in total
    for (uint256 i = 0; i < _ids.length; i++) {
      require(
        itemRangeMin <= _ids[i] && _ids[i] <= itemRangeMax, 
        "BondingCurveFactory#onERC1155BatchReceived: ID_IS_INVALID"
      );
      nItems = nItems.add(_amounts[i]);
    }

    return nItems;
  }

  /**
   * @notice Get item and usdc cost of all items a minting order
   * @param _ids      Ids of items to mint
   * @param _amounts  Amount of each item to be minted
   */
  function getMintingTotalCost(uint256[] memory _ids, uint256[] memory _amounts) view public returns (uint256 nItems, uint256 nUSDC) {
    // Count how many valid items were sent in total
    uint256 totalAmount = 0;
    for (uint256 i = 0; i < _ids.length; i++) {
      totalAmount = totalAmount.add(_amounts[i]);
    }
    return (totalAmount.mul(COST_IN_ITEMS), usdcTotalCost(_ids, _amounts));
  }

  /**
   * @notice Get item and usdc cost of each item in an order
   * @param _ids      Ids of items to mint
   * @param _amounts  Amount of each item to be minted
   */
  function getMintingCost(uint256[] memory _ids, uint256[] memory _amounts) view public returns (uint256[] memory, uint256[] memory) {
    // Initialize return arrays
    uint256[] memory nItems = new uint256[](_ids.length);
    uint256[] memory nUSDC = new uint256[](_ids.length);

    // Count how many valid items were sent in total
    for (uint256 i = 0; i < _ids.length; i++) {
      nItems[i] =  _amounts[i].mul(COST_IN_ITEMS);
      nUSDC[i] = usdcCost(_ids[i],  _amounts[i]);
    }

    return (nItems, nUSDC);
  }

  /**
   * @notice Returns the cost in USDC, which is based on a bonding curve
   * @param _ids     Ids of items to mint
   * @param _amounts Amount of each item to be minted
   */
  function usdcTotalCost(uint256[] memory _ids, uint256[] memory _amounts) view public returns (uint256 nUSDC) {
    for (uint256 i = 0; i < _ids.length; i++) {
      nUSDC = nUSDC.add(usdcCost(_ids[i], _amounts[i]));
    }
    return nUSDC;
  }

    /**
   * @notice Returns the cost in USDC, which is based on a bonding curve
   * @param _id     ID of item to be minted
   * @param _amount Amount of item to be minted
   */
  function usdcCost(uint256 _id, uint256 _amount) view public returns (uint256 nUSDC) {
    uint256 supply = mintedAmounts[_id];
    uint256 amount = _amount;

    // Go over all the price ticks 
    while (amount > 0) {
      // Check how many can be minted in current tick
      uint256 leftInTick = USDC_CURVE_TICK_SIZE.sub(supply % USDC_CURVE_TICK_SIZE);

      // Check how many will be minted in current tick
      uint256 amountInTick = leftInTick > amount ? amount : leftInTick;

      // Add to the total cost
      nUSDC = nUSDC.add(amountInTick.mul(usdcCurve(supply)));

      // Remove amount to be minted in current tick from total amount
      amount = amount.sub(amountInTick);

      // Increase supply
      supply = supply.add(amountInTick);
    }

    return nUSDC;
  }

  /**
   * @notice Returns value in curve
   * @dev Curve is (x+k)^2 / m
   * @param _x point on the curve, multiple of 100
   */
  function usdcCurve(uint256 _x) view public returns (uint256 nUsdc) {
    // Lower bound of the tick is the price
    // E.g. 1500 will be priced at 1000
    uint256 tickValue = _x.div(USDC_CURVE_TICK_SIZE).mul(USDC_CURVE_TICK_SIZE); 
    // (x+k)^2
    uint256 base = tickValue.add(USDC_CURVE_CONSTANT);
    uint256 exponent = base.mul(base);
    // exponent / m
    return exponent.div(USDC_CURVE_SCALE_DOWN);
  }


  /**
   * @notice Send ERC-20 balance to recipient
   * @param _recipient Address where the currency will be sent to
   * @param _erc20     Address of ERC-20 token to transfer out
   */
  function withdrawERC20(address _recipient, address _erc20) external onlyOwnerTier(HIGHEST_OWNER_TIER) {
    require(_recipient != address(0x0), "BondingCurveFactory#withdrawERC20: INVALID_RECIPIENT");
    uint256 this_balance = IERC20(_erc20).balanceOf(address(this));
    IERC20(_erc20).transfer(_recipient, this_balance);
  }


  /***********************************|
  |         Utility Functions         |
  |__________________________________*/

  /**
   * @notice Indicates whether a contract implements a given interface.
   * @param interfaceID The ERC-165 interface ID that is queried for support.
   * @return True if contract interface is supported.
   */
  function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
    return  interfaceID == type(IERC165).interfaceId || 
      interfaceID == type(IERC1155TokenReceiver).interfaceId;
  }
}

pragma solidity 0.7.4;

import "../utils/TieredOwnable.sol";
import "../interfaces/ISkyweaverAssets.sol";
import "@0xsequence/erc-1155/contracts/utils/SafeMath.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC165.sol";

/**
 * @notice This is a contract allowing contract owner to mint up to N 
 *         assets per period of 6 hours.
 * @dev This contract should only be able to mint some asset types
 */
contract RewardFactory is TieredOwnable {
  using SafeMath for uint256;

  /***********************************|
  |             Variables             |
  |__________________________________*/

  // Token information
  ISkyweaverAssets immutable public skyweaverAssets; // ERC-1155 Skyweaver assets contract

  // Period variables
  uint256 internal period;                // Current period
  uint256 internal availableSupply;       // Amount of assets that can currently be minted
  uint256 public periodMintLimit;         // Amount that can be minted within 6h
  uint256 immutable public PERIOD_LENGTH; // Length of each mint periods in seconds

  // Whitelist
  bool internal immutable MINT_WHITELIST_ONLY;
  mapping(uint256 => bool) public mintWhitelist;

  // Event
  event PeriodMintLimitChanged(uint256 oldMintingLimit, uint256 newMintingLimit);
  event AssetsEnabled(uint256[] enabledIds);
  event AssetsDisabled(uint256[] disabledIds);
  
  /***********************************|
  |            Constructor            |
  |__________________________________*/

  /**
   * @notice Create factory, link skyweaver assets and store initial parameters
   * @param _firstOwner      Address of the first owner
   * @param _assetsAddr      The address of the ERC-1155 Assets Token contract
   * @param _periodLength    Number of seconds each period lasts
   * @param _periodMintLimit Can only mint N assets per period
   * @param _whitelistOnly   Whether this factory uses a mint whitelist or not
   */
  constructor(
    address _firstOwner,
    address _assetsAddr,
    uint256 _periodLength,
    uint256 _periodMintLimit,
    bool _whitelistOnly
  ) TieredOwnable(_firstOwner) public {
    require(
      _assetsAddr != address(0) &&
      _periodLength > 0 &&
      _periodMintLimit > 0,
      "RewardFactory#constructor: INVALID_INPUT"
    );

    // Assets
    skyweaverAssets = ISkyweaverAssets(_assetsAddr);

    // Set Period length
    PERIOD_LENGTH = _periodLength;

    // Set whether this factory uses a mint whitelist or not
    MINT_WHITELIST_ONLY = _whitelistOnly;

    // Set current period
    period = block.timestamp / _periodLength; // From livePeriod()
    availableSupply = _periodMintLimit;

    // Rewards parameters
    periodMintLimit = _periodMintLimit;
    emit PeriodMintLimitChanged(0, _periodMintLimit);
  }


  /***********************************|
  |         Management Methods        |
  |__________________________________*/

  /**
   * @notice Will update the daily mint limit
   * @dev This change will take effect immediatly once executed
   * @param _newPeriodMintLimit Amount of assets that can be minted within a period
   */
  function updatePeriodMintLimit(uint256 _newPeriodMintLimit) external onlyOwnerTier(HIGHEST_OWNER_TIER) {
    // Immediately update supply instead of waiting for next period
    if (availableSupply > _newPeriodMintLimit) {
      availableSupply = _newPeriodMintLimit;
    }

    emit PeriodMintLimitChanged(periodMintLimit, _newPeriodMintLimit);
    periodMintLimit = _newPeriodMintLimit;
  }

  /**
   * @notice Will enable these tokens to be minted by this factory
   * @param _enabledIds IDs this factory can mint
   */
  function enableMint(uint256[] calldata _enabledIds) external onlyOwnerTier(HIGHEST_OWNER_TIER) {
    for (uint256 i = 0; i < _enabledIds.length; i++) {
      mintWhitelist[_enabledIds[i]] = true;
    }
    emit AssetsEnabled(_enabledIds);
  }

  /**
   * @notice Will prevent these ids from being minted by this factory
   * @param _disabledIds IDs this factory can mint
   */
  function disableMint(uint256[] calldata _disabledIds) external onlyOwnerTier(HIGHEST_OWNER_TIER) {
    for (uint256 i = 0; i < _disabledIds.length; i++) {
      mintWhitelist[_disabledIds[i]] = false;
    }
    emit AssetsDisabled(_disabledIds);
  }


  /***********************************|
  |      Receiver Method Handler      |
  |__________________________________*/

  /**
   * @notice Prevents receiving Ether or calls to unsuported methods
   */
  fallback () external {
    revert("RewardFactory#_: UNSUPPORTED_METHOD");
  }

  /***********************************|
  |         Minting Functions         |
  |__________________________________*/

  /**
   * @notice Will mint tokens to user
   * @dev Can only mint up to the periodMintLimit in a given 6hour period
   * @param _to      The address that receives the assets
   * @param _ids     Array of Tokens ID that are minted
   * @param _amounts Amount of Tokens id minted for each corresponding Token id in _ids
   * @param _data    Byte array passed to recipient if recipient is a contract
   */
  function batchMint(address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data)
    external onlyOwnerTier(1)
  {
    uint256 live_period = livePeriod();
    uint256 stored_period = period;
    uint256 available_supply;

    // Update period and refresh the available supply if period
    // is different, otherwise use current available supply.
    if (live_period == stored_period) {
      available_supply = availableSupply;
    } else {
      available_supply = periodMintLimit;
      period = live_period;
    }

    // If there is an insufficient available supply, this will revert
    for (uint256 i = 0; i < _ids.length; i++) {
      available_supply = available_supply.sub(_amounts[i]);
      if (MINT_WHITELIST_ONLY) {
        require(mintWhitelist[_ids[i]], "RewardFactory#batchMint: ID_IS_NOT_WHITELISTED");
      }
    }

    // Store available supply
    availableSupply = available_supply;
    
    // Mint assets
    skyweaverAssets.batchMint(_to, _ids, _amounts, _data);
  }


  /***********************************|
  |         Utility Functions         |
  |__________________________________*/

  /**
   * @notice Returns how many cards can currently be minted by this factory
   */
  function getAvailableSupply() external view returns (uint256) {
    return livePeriod() == period ? availableSupply : periodMintLimit;
  }

  /**
   * @notice Calculate the current period
   */
  function livePeriod() public view returns (uint256) {
    return block.timestamp / PERIOD_LENGTH;
  }

  /**
   * @notice Indicates whether a contract implements a given interface.
   * @param interfaceID The ERC-165 interface ID that is queried for support.
   * @return True if contract interface is supported.
   */
  function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
    return  interfaceID == type(IERC165).interfaceId;
  }
}

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface ISkyweaverAssets {

  /***********************************|
  |               Events              |
  |__________________________________*/

  event FactoryActivation(address indexed factory);
  event FactoryShutdown(address indexed factory);
  event MintPermissionAdded(address indexed factory, AssetRange new_range);
  event MintPermissionRemoved(address indexed factory, AssetRange deleted_range);

  // Struct for mint ID ranges permissions
  struct AssetRange {
    uint256 minID;
    uint256 maxID;
  }

  /***********************************|
  |    Supplies Management Methods    |
  |__________________________________*/

  /**
   * @notice Set max issuance for some token IDs that can't ever be increased
   * @dev Can only decrease the max issuance if already set, but can't set it *back* to 0.
   * @param _ids Array of token IDs to set the max issuance
   * @param _newMaxIssuances Array of max issuances for each corresponding ID
   */
  function setMaxIssuances(uint256[] calldata _ids, uint256[] calldata _newMaxIssuances) external;

  /***********************************|
  |     Factory Management Methods    |
  |__________________________________*/

  /**
   * @notice Will allow a factory to mint some token ids
   * @param _factory   Address of the factory to update permission
   * @param _minRange  Minimum ID (inclusive) in id range that factory will be able to mint
   * @param _maxRange  Maximum ID (inclusive) in id range that factory will be able to mint
   * @param _startTime Timestamp when the range becomes valid
   * @param _endTime   Timestamp after which the range is no longer valid 
   */
  function addMintPermission(address _factory, uint64 _minRange, uint64 _maxRange, uint64 _startTime, uint64 _endTime) external;

  /**
   * @notice Will remove the permission a factory has to mint some token ids
   * @param _factory    Address of the factory to update permission
   * @param _rangeIndex Array's index where the range to delete is located for _factory
   */
  function removeMintPermission(address _factory, uint256 _rangeIndex) external;

  /**
   * @notice Will ALLOW factory to print some assets specified in `canPrint` mapping
   * @param _factory Address of the factory to activate
   */
  function activateFactory(address _factory) external;

  /**
   * @notice Will DISALLOW factory to print any asset
   * @param _factory Address of the factory to shutdown
   */
  function shutdownFactory(address _factory) external;

  /**
   * @notice Will forever prevent new mint permissions for provided ids
   * @param _range AssetRange struct for range of asset that can't be granted
   *               new mint permission to
   */
  function lockRangeMintPermissions(AssetRange calldata _range) external;


  /***********************************|
  |         Getter Functions          |
  |__________________________________*/

  /**
   * @return Returns whether a factory is active or not
   */
  function getFactoryStatus(address _factory) external view returns (bool);

  /**
   * @return Returns whether the sale has ended or not
   */
  function getFactoryAccessRanges(address _factory) external view returns ( AssetRange[] memory);

  /**
   * @notice Get the max issuance of multiple asset IDs
   * @dev The max issuance of a token does not reflect the maximum supply, only
   *      how many tokens can be minted once the maxIssuance for a token is set.
   * @param _ids Array containing the assets IDs
   * @return The current max issuance of each asset ID in _ids
   */
  function getMaxIssuances(uint256[] calldata _ids) external view returns (uint256[] memory);

  /**
   * @notice Get the current issuanc of multiple asset ID
   * @dev The current issuance of a token does not reflect the current supply, only
   *      how many tokens since a max issuance was set for a given token id.
   * @param _ids Array containing the assets IDs
   * @return The current issuance of each asset ID in _ids
   */
  function getCurrentIssuances(uint256[] calldata _ids)external view returns (uint256[] memory);

  /***************************************|
  |           Minting Functions           |
  |______________________________________*/

  /**
   * @dev Mint _amount of tokens of a given id if not frozen and if max supply not exceeded
   * @param _to     The address to mint tokens to.
   * @param _id     Token id to mint
   * @param _amount The amount to be minted
   * @param _data   Byte array of data to pass to recipient if it's a contract
   */
  function mint(address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;

  /**
   * @dev Mint tokens for each ids in _ids
   * @param _to      The address to mint tokens to.
   * @param _ids     Array of ids to mint
   * @param _amounts Array of amount of tokens to mint per id
   * @param _data    Byte array of data to pass to recipient if it's a contract
   */
  function batchMint(address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;


  /***************************************|
  |           Burning Functions           |
  |______________________________________*/

  /**
   * @notice Burn sender's_amount of tokens of a given token id
   * @param _id      Token id to burn
   * @param _amount  The amount to be burned
   */
  function burn(uint256 _id, uint256 _amount) external;

  /**
   * @notice Burn sender's tokens of given token id for each (_ids[i], _amounts[i]) pair
   * @param _ids      Array of token ids to burn
   * @param _amounts  Array of the amount to be burned
   */
  function batchBurn(uint256[] calldata _ids, uint256[] calldata _amounts) external;
}

pragma solidity 0.7.4;

/**
 * @notice The TieredOwnable can assign ownership tiers to addresses,
 * allowing inheriting contracts to choose which tier can call which function.
 */
contract TieredOwnable {
  uint256 constant internal HIGHEST_OWNER_TIER = 2**256-1; //Highest possible tier

  mapping(address => uint256) internal ownerTier;
  event OwnershipGranted(address indexed owner, uint256 indexed previousTier, uint256 indexed newTier);

  /**
   * @dev Sets the _firstOwner provided to highest owner tier
   * @dev _firstOwner First address to be a owner of this contract
   */
  constructor (address _firstOwner) {
    require(_firstOwner != address(0), "TieredOwnable#constructor: INVALID_FIRST_OWNER");
    ownerTier[_firstOwner] = HIGHEST_OWNER_TIER;
    emit OwnershipGranted(_firstOwner, 0, HIGHEST_OWNER_TIER);
  }

  /**
   * @dev Throws if called by an account that's in lower ownership tier than expected
   */
  modifier onlyOwnerTier(uint256 _minTier) {
    require(ownerTier[msg.sender] >= _minTier, "TieredOwnable#onlyOwnerTier: OWNER_TIER_IS_TOO_LOW");
    _;
  }

  /**
   * @notice Highest owners can change ownership tier of other owners
   * @dev Prevents changing sender's tier to ensure there is always at least one HIGHEST_OWNER_TIER owner.
   * @param _address Address of the owner
   * @param _tier    Ownership tier assigned to owner
   */
  function assignOwnership(address _address, uint256 _tier) external onlyOwnerTier(HIGHEST_OWNER_TIER) {
    require(_address != address(0), "TieredOwnable#assignOwnership: INVALID_ADDRESS");
    require(msg.sender != _address, "TieredOwnable#assignOwnership: UPDATING_SELF_TIER");
    emit OwnershipGranted(_address, ownerTier[_address], _tier);
    ownerTier[_address] = _tier;
  }

  /**
   * @notice Returns the ownership tier of provided owner
   * @param _owner Owner's address to query ownership tier
   */
  function getOwnerTier(address _owner) external view returns (uint256) {
    return ownerTier[_owner];
  }
}

pragma solidity 0.7.4;

import "@horizongames/skyweaver-contracts/contracts/factories/RewardFactory.sol";

contract ConquestPointsGoldRewardFactory is RewardFactory {
  constructor(
    address _initialOwner,
    address _assetsAddr,
    uint256 _periodLength,
    uint256 _periodMintLimit,
    bool _whitelistOnly
  ) RewardFactory(_initialOwner, _assetsAddr, _periodLength, _periodMintLimit, _whitelistOnly) public {}
}

pragma solidity 0.7.4;

import "@horizongames/skyweaver-contracts/contracts/factories/RewardFactory.sol";

contract CrystalFactory is RewardFactory {
  constructor(
    address _initialOwner,
    address _assetsAddr,
    uint256 _periodLength,
    uint256 _periodMintLimit,
    bool _whitelistOnly
  ) RewardFactory(_initialOwner, _assetsAddr, _periodLength, _periodMintLimit, _whitelistOnly) public {}
}

pragma solidity 0.7.4;

import "@horizongames/skyweaver-contracts/contracts/factories/RewardFactory.sol";

contract FreeConquestEntriesFactory is RewardFactory {
  constructor(
    address _initialOwner,
    address _assetsAddr,
    uint256 _periodLength,
    uint256 _periodMintLimit,
    bool _whitelistOnly
  ) RewardFactory(_initialOwner, _assetsAddr, _periodLength, _periodMintLimit, _whitelistOnly) public {}
}

pragma solidity 0.7.4;

import "@horizongames/skyweaver-contracts/contracts/factories/RewardFactory.sol";

contract GoldRewardFactory is RewardFactory {
  constructor(
    address _initialOwner,
    address _assetsAddr,
    uint256 _periodLength,
    uint256 _periodMintLimit,
    bool _whitelistOnly
  ) RewardFactory(_initialOwner, _assetsAddr, _periodLength, _periodMintLimit, _whitelistOnly) public {}
}

pragma solidity 0.7.4;

import "@horizongames/skyweaver-contracts/contracts/factories/RewardFactory.sol";

contract LeaderboardRewardFactory is RewardFactory {
  constructor(
    address _initialOwner,
    address _assetsAddr,
    uint256 _periodLength,
    uint256 _periodMintLimit,
    bool _whitelistOnly
  ) RewardFactory(_initialOwner, _assetsAddr, _periodLength, _periodMintLimit, _whitelistOnly) public {}
}

pragma solidity 0.7.4;

import "@horizongames/skyweaver-contracts/contracts/factories/RewardFactory.sol";

contract LeaderboardTicketRewardFactory is RewardFactory {
  constructor(
    address _initialOwner,
    address _assetsAddr,
    uint256 _periodLength,
    uint256 _periodMintLimit,
    bool _whitelistOnly
  ) RewardFactory(_initialOwner, _assetsAddr, _periodLength, _periodMintLimit, _whitelistOnly) public {}
}

pragma solidity 0.7.4;

import "@horizongames/skyweaver-contracts/contracts/factories/RewardFactory.sol";

contract LegacyHeroFactory is RewardFactory {
  constructor(
    address _initialOwner,
    address _assetsAddr,
    uint256 _periodLength,
    uint256 _periodMintLimit,
    bool _whitelistOnly
  ) RewardFactory(_initialOwner, _assetsAddr, _periodLength, _periodMintLimit, _whitelistOnly) public {}
}

pragma solidity 0.7.4;

import "@horizongames/skyweaver-contracts/contracts/factories/BondingCurveFactory.sol";

contract LegacyHeroSale is BondingCurveFactory {
  constructor(
    address _firstOwner,
    uint256 _usdc,
    address _skyweaverAssetsAddress,
    uint256 _itemRangeMin,
    uint256 _itemRangeMax,
    uint256 _costInItems,
    uint256 _usdcCurveConstant,
    uint256 _usdcCurveScaleDown,
    uint256 _usdcCurveTickSize
  ) BondingCurveFactory(_firstOwner, _usdc, _skyweaverAssetsAddress, _itemRangeMin, _itemRangeMax, _costInItems, _usdcCurveConstant, _usdcCurveScaleDown, _usdcCurveTickSize) public {}
}

pragma solidity 0.7.4;

import "@horizongames/skyweaver-contracts/contracts/factories/RewardFactory.sol";

contract StickersFactory is RewardFactory {
  constructor(
    address _initialOwner,
    address _assetsAddr,
    uint256 _periodLength,
    uint256 _periodMintLimit,
    bool _whitelistOnly
  ) RewardFactory(_initialOwner, _assetsAddr, _periodLength, _periodMintLimit, _whitelistOnly) public {}
}

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "@0xsequence/erc20-meta-token/contracts/mocks/ERC20Mock.sol";

contract USDC is ERC20Mock {
  uint256 constant decimals = 6;
}