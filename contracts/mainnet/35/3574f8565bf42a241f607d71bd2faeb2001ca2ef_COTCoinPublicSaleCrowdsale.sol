/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.4.23;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts/WhiteList.sol

pragma solidity ^0.4.21;


contract WhiteList is Ownable{


	mapping(address => uint8) public whitelist;
	bool public publicsale_need_whitelist = true;

	event ImportList(address indexed owner, address[] users, uint8 flag);
	event UpdatePublicSaleWhitelistStatus(address indexed owner, bool flag);

  	/**
	* @dev Function to import user's address into whitelist, only user who in the whitelist can purchase token.
	*      Whitelistにユーザーアドレスを記録。sale期間に、Whitelistに記録したユーザーたちしかトークンを購入できない
	* @param _users The address list that can purchase token when sale period.
	* @param _flag The flag for record different lv user, 1: pre sale user, 2: public sale user. 3: premium sale user
	* @return A bool that indicates if the operation was successful.
	*/
	function importList(address[] _users, uint8 _flag) onlyOwner public returns(bool){

		require(_users.length > 0);

        for(uint i = 0; i < _users.length; i++) {
            whitelist[_users[i]] = _flag;
        }		

        emit ImportList(msg.sender, _users, _flag);

		return true;
	}

  	/**
	* @dev Function check the current user can purchase token or not.
	*      ユーザーアドレスはWhitelistに記録かどうかチェック
	* @param _user The user address that can purchase token or not when public salse.
	* @return A bool that indicates if the operation was successful.
	*/
	function checkList(address _user)public view returns(uint8){
		return whitelist[_user];
	}

  	/**
	* @dev Function get whitelist able status in public sale 
	* @return A bool that indicates if the operation was successful.
	*/
	function getPublicSaleWhitelistStatus()public view returns(bool){
		return publicsale_need_whitelist;
	}	

  	/**
	* @dev Function update whitelist able status in public sale 
	* @param _flag bool whitelist status
	* @return A bool that indicates if the operation was successful.
	*/
	function updatePublicSaleWhitelistStatus(bool _flag) onlyOwner public returns(bool){
		publicsale_need_whitelist = _flag;

		emit UpdatePublicSaleWhitelistStatus(msg.sender, _flag);

		return true;
	}	
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.23;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/Deliver.sol

pragma solidity ^0.4.21;



contract Deliver is Ownable{
	using SafeMath for uint256;

	mapping(address => uint256) public waiting_plate;
	mapping(bytes32 => uint256) public token_deliver_date_plate;
	mapping(bytes32 => uint256) public token_deliver_plate;
	mapping(bytes32 => bool) public already_deliver_token;
	mapping(address => uint256) public deliver_balance;
	mapping(bytes32 => address) public hash_mapping;
	mapping(bytes32 => bool) public deliver_suspending;

	event UpdateWaitingPlate(address indexed updater, address indexed user, uint256 waiting_time);
	event UpdateTokenDeliverPlate(address indexed updater, bytes32 indexed hash_id, uint256 token_amount);
	event UpdateTokenDeliverCheck(address indexed updater, bytes32 indexed hash_id, bool flag);
	event UpdateTokenDeliverBalance(address indexed updater, address indexed user, uint256 pending_token_amount);
	event UpdateHashMapping(address indexed updater, bytes32 indexed hash_id, address indexed user);
	event UpdateDeliverSuspending(address indexed updater, bytes32 indexed hash_id, bool deliver_suspending);

	/**
	* @dev called for get user waiting time
	* @param _user Address
	* @return A uint256 that if the operation was successful.
	*/
	function getWaitingPlate(address _user) public view returns(uint256){
		return waiting_plate[_user];
	}
	
	/**
	* @dev called for get user deliver date
	* @param _hash_id transaction unique hash id
	* @return A uint256 that if the operation was successful.
	*/
	function getTokenDeliverDatePlate(bytes32 _hash_id) public view returns(uint256){
		return token_deliver_date_plate[_hash_id];
	}

	/**
	* @dev called for get user waiting time
	* @param _hash_id transaction unique hash id
	* @return A uint256 that if the operation was successful.
	*/
	function getTokenDeliverPlate(bytes32 _hash_id) public view returns(uint256){
		return token_deliver_plate[_hash_id];
	}

	/**
	* @dev called for get user total pending token amount
	* @param _user user address
	* @return A uint256 that if the operation was successful.
	*/
	function getPendingDeliverToken(address _user) public view returns(uint256){
		return deliver_balance[_user];
	}

	/**
	* @dev called for get user address from hash_id
	* @param _hash_id transaction unique hash id
	* @return A address that if the operation was successful.
	*/
	function getHashMappingAddress(bytes32 _hash_id) public view returns(address){
		return hash_mapping[_hash_id];
	}

	/**
	* @dev called for get user token deliver suspending status
	* @param _hash_id transaction unique hash id
	* @return A bool that if the operation was successful.
	*/
	function getDeliverSuspending(bytes32 _hash_id) public view returns(bool){
		return deliver_suspending[_hash_id];
	}

	/**
	* @dev called for get user total pending token amount
	* @param _hash_id transaction unique hash id
	* @return A bool that if the operation was successful.
	*/
	function deliverCheck(bytes32 _hash_id) public view returns(bool){
		return already_deliver_token[_hash_id];
	}

	/**
	* @dev called for insert user waiting time
	* @param _users Address list
	* @param _waiting_times 時期申告時間リスト
	* @return A bool that if the operation was successful.
	*/
	function pushWaitingPlate(address[] _users, uint256[] _waiting_times)onlyOwner public returns(bool){

		require(_users.length > 0 && _waiting_times.length > 0);
		require(_users.length == _waiting_times.length);

		address user;
		uint256 waiting_time;

        for(uint i = 0; i < _users.length; i++) {
        	user = _users[i];
        	waiting_time = _waiting_times[i];

            waiting_plate[user] = waiting_time;

            emit UpdateWaitingPlate(msg.sender, user, waiting_time);
        }		

		return true;

	}

	/**
	* @dev called for insert user waiting time
	* @param _hash_id transaction unique hash id
	* @param _suspending ユーザーのトークン配布禁止フラグ
	* @return A bool that if the operation was successful.
	*/
	function updateDeliverSuspending(bytes32 _hash_id, bool _suspending)onlyOwner public returns(bool){
		deliver_suspending[_hash_id] = _suspending;

		emit UpdateDeliverSuspending(msg.sender, _hash_id, _suspending);
		return true;
	}

	/**
	* @dev called for insert user token info in the mapping
	* @param _hash_id transaction unique hash id
	* @param _total_token_amount the token amount that include bonus
	* @return A bool that if the operation was successful.
	*/
	function pushTokenDeliverPlate(address _beneficiary, bytes32 _hash_id, uint256 _total_token_amount, uint256 _deliver_date)onlyOwner public returns(bool){

		require(_total_token_amount > 0);

		token_deliver_plate[_hash_id] = _total_token_amount;
		already_deliver_token[_hash_id] = false;
		deliver_balance[_beneficiary] = deliver_balance[_beneficiary].add(_total_token_amount);
		hash_mapping[_hash_id] = _beneficiary;
		token_deliver_date_plate[_hash_id] = _deliver_date;

		emit UpdateTokenDeliverPlate(msg.sender, _hash_id, _total_token_amount);
		emit UpdateTokenDeliverCheck(msg.sender, _hash_id, true);
		emit UpdateTokenDeliverBalance(msg.sender, _beneficiary, deliver_balance[_beneficiary]);
		emit UpdateHashMapping(msg.sender, _hash_id, _beneficiary);
		return true;
	}

	/**
	* @dev called for reset user token info in the mapping
	* @param _hash_id transaction unique hash id
	* @return A bool that if the operation was successful.
	*/
	function resetTokenDeliverPlate(address _beneficiary, bytes32 _hash_id, uint256 _token_amount)onlyOwner public returns(bool){

		require(_token_amount > 0);

		token_deliver_plate[_hash_id] = 0;
		already_deliver_token[_hash_id] = true;
		deliver_balance[_beneficiary] = deliver_balance[_beneficiary].sub(_token_amount);

		emit UpdateTokenDeliverPlate(msg.sender, _hash_id, 0);
		emit UpdateTokenDeliverCheck(msg.sender, _hash_id, false);
		emit UpdateTokenDeliverBalance(msg.sender, _beneficiary, deliver_balance[_beneficiary]);
		return true;
	}

}

// File: contracts/Bonus.sol

pragma solidity ^0.4.21;



contract Bonus is Ownable{
	using SafeMath for uint256;

	uint256 public constant day = 24*60*60;

	uint256 public publicSale_first_stage_endTime;

	mapping(uint8 => uint256) public bonus_time_gate;
	mapping(uint8 => uint8) public bonus_rate;

	event UpdateBonusPhase(address indexed updater, uint8 indexed phase_type, uint256 time_gate, uint8 bonus);
	event UpdatePublicSaleFirstStageEndTime(address indexed updater, uint256 publicSale_first_stage_endTime);

	constructor(
		uint256 _publicSale_first_stage_endTime,
		uint256 _bonus_time_gate_1, 
		uint256 _bonus_time_gate_2,
		uint256 _bonus_time_gate_3, 
		uint256 _bonus_time_gate_4,
		uint8 _bonus_rate_1, 
		uint8 _bonus_rate_2,
		uint8 _bonus_rate_3,
		uint8 _bonus_rate_4) public
	{
		bonus_time_gate[0] = _bonus_time_gate_1*uint256(day);
		bonus_time_gate[1] = _bonus_time_gate_2*uint256(day);
		bonus_time_gate[2] = _bonus_time_gate_3*uint256(day);
		bonus_time_gate[3] = _bonus_time_gate_4*uint256(day);

		bonus_rate[0] = _bonus_rate_1;
		bonus_rate[1] = _bonus_rate_2;
		bonus_rate[2] = _bonus_rate_3;
		bonus_rate[3] = _bonus_rate_4;
	
		publicSale_first_stage_endTime = _publicSale_first_stage_endTime;

		emit UpdateBonusPhase(msg.sender, 1, _bonus_time_gate_1, _bonus_rate_1);
		emit UpdateBonusPhase(msg.sender, 2, _bonus_time_gate_2, _bonus_rate_2);
		emit UpdateBonusPhase(msg.sender, 3, _bonus_time_gate_3, _bonus_rate_3);
		emit UpdateBonusPhase(msg.sender, 4, _bonus_time_gate_4, _bonus_rate_4);
	}

	/**
	* @dev called for get bonus rate
	* @param _phase_type uint8 bonus phase block
	* @return A uint8, bonus rate that if the operation was successful.
	*/
	function getBonusRate(uint8 _phase_type) public view returns(uint8){
		return bonus_rate[_phase_type];
	}

	/**
	* @dev called for get bonus time block
	* @param _phase_type uint8 bonus phase block
	* @return A uint8, phase block time that if the operation was successful.	
	*/
	function getBonusTimeGate(uint8 _phase_type) public view returns(uint256){
		return bonus_time_gate[_phase_type];
	}

	/**
	* @dev called for get the public sale first stage end time
	* @return A uint256, the public sale first stage end time that if the operation was successful.	
	*/
	function getPublicSaleFirstStageEndTime() public view returns(uint256){
		return publicSale_first_stage_endTime;
	}

	/**
	* @dev called for get total token amount that include the bonus
	* @param _waiting_time uint256 KYV waiting time
	* @param _tokenAmount uint256 basic token amount
	* @return A uint256, total token amount that if the operation was successful.		
	*/
	function getTotalAmount(uint256 _waiting_time, uint256 _tokenAmount) public view returns(uint256){
		uint256 total_token_amount;

		if(_waiting_time < bonus_time_gate[0]){
			//user still can get bonus if user purchase token before publicSale first stage end time.
			if(now <= publicSale_first_stage_endTime){
				total_token_amount = _tokenAmount + (_tokenAmount * uint256(bonus_rate[0])) / 100;
			}else{
				total_token_amount = _tokenAmount;
			}
		}else if(_waiting_time < bonus_time_gate[1]){
			total_token_amount = _tokenAmount + (_tokenAmount * uint256(bonus_rate[0])) / 100;
		}else if(_waiting_time < bonus_time_gate[2]){
			total_token_amount = _tokenAmount + (_tokenAmount * uint256(bonus_rate[1])) / 100;
		}else if(_waiting_time < bonus_time_gate[3]){
			total_token_amount = _tokenAmount + (_tokenAmount * uint256(bonus_rate[2])) / 100;
		}else{
			total_token_amount = _tokenAmount + (_tokenAmount * uint256(bonus_rate[3])) / 100;
		}

		return total_token_amount;
	}
	
	/**
	* @dev called for update the public sale first stage end time
	* @param _new_stage_endTime uint256 new public sale first stage end time
	* @return A uint256, the public sale first stage end time that if the operation was successful.	
	*/
	function updatePublicSaleFirstStageEndTime(uint256 _new_stage_endTime)onlyOwner public returns(bool){
		publicSale_first_stage_endTime = _new_stage_endTime;

		emit UpdatePublicSaleFirstStageEndTime(msg.sender, _new_stage_endTime);
		return true;
	}

	/**
	* @dev called for update bonus phase time block and rate
	* @param _phase_type uint8 phase block
	* @param _new_days uint256 new phase block time
	* @param _new_bonus uint8 new rate
	* @return A bool that if the operation was successful.
	*/
	function updateBonusPhase(uint8 _phase_type, uint256 _new_days, uint8 _new_bonus)onlyOwner public returns(bool){

		uint256 _new_gate = _new_days * uint256(day);

		//gate phase only have 4 phase
		require(0 < _phase_type && _phase_type <= 4);

		//gate phase 1
		if(_phase_type == 1){

			//new gate time needs to be early than the next gate time
			require( _new_gate < bonus_time_gate[1] );

			//new gate rate needs to be less than the next gate's rate
			require( _new_bonus < bonus_rate[1] );

			bonus_time_gate[0] = _new_gate;
			bonus_rate[0] = _new_bonus;
		}else if(_phase_type == 2){

			//new gate time needs to be early than the next gate time and need to be late than the perious gate time
			require( bonus_time_gate[0] < _new_gate && _new_gate < bonus_time_gate[2] );

			//new gate rate needs to be less than the next gate's rate and need to be bigger than the perious gate rate
			require( bonus_rate[0] < _new_bonus && _new_bonus < bonus_rate[2] );

			bonus_time_gate[1] = _new_gate;
			bonus_rate[1] = _new_bonus;
		}else if(_phase_type == 3){

			require( bonus_time_gate[1] < _new_gate && _new_gate < bonus_time_gate[3] );
			require( bonus_rate[1] < _new_bonus && _new_bonus < bonus_rate[3] );

			bonus_time_gate[2] = _new_gate;
			bonus_rate[2] = _new_bonus;
		}else{

			require( bonus_time_gate[2] < _new_gate );
			require( bonus_rate[2] < _new_bonus );

			bonus_time_gate[3] = _new_gate;
			bonus_rate[3] = _new_bonus;
		}

		emit UpdateBonusPhase(msg.sender, _phase_type, _new_days, _new_bonus);
	}
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

pragma solidity ^0.4.23;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.4.23;



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol

pragma solidity ^0.4.23;




/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropiate to concatenate
 * behavior.
 */
contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei.
  // The rate is the conversion between wei and the smallest and indivisible token unit.
  // So, if you are using a rate of 1 with a DetailedERC20 token with 3 decimals called TOK
  // 1 wei will give you 1 unit, or 0.001 TOK.
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () external payable {
    buyTokens(msg.sender);
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.transfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

// File: openzeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol

pragma solidity ^0.4.23;




/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

  /**
   * @dev Constructor, takes crowdsale opening and closing times.
   * @param _openingTime Crowdsale opening time
   * @param _closingTime Crowdsale closing time
   */
  constructor(uint256 _openingTime, uint256 _closingTime) public {
    // solium-disable-next-line security/no-block-members
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp > closingTime;
  }

  /**
   * @dev Extend parent behavior requiring to be within contributing period
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyWhileOpen
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

pragma solidity ^0.4.23;



/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: contracts/COTCoinPublicSaleCrowdsale.sol

pragma solidity ^0.4.21;








contract COTCoinPublicSaleCrowdsale is TimedCrowdsale, Ownable, Pausable{
	using SafeMath for uint256;

	address public admin_wallet; //wallet to controll system
	address public sale_owner_wallet; 
	address public eth_management_wallet; //wallet to reveive eth
	address public refund_token_wallet; //wallet that contract will return token
	address public cot_sale_wallet;

	uint256 public minimum_weiAmount;

	uint256 public public_opening_time;
	uint256 public public_closing_time;

	WhiteList public white_list;
	Deliver public deliver;
	Bonus public bonus;

	uint256 public pending_balance;

	event UpdateRate(address indexed updater, uint256 transaction_date, uint256 rate);
	event ReFundToken(address indexed from, address indexed to, uint256 token_amount);
	event PublicsalePurchase(address indexed beneficiary, 
							uint256 transaction_date,
							uint256 waiting_time, 
							uint256 deliver_date, 
							uint256 value, 
							uint256 origin_token_amount, 
							uint256 total_token_amount,
							bytes32 hash_id,
							uint256 sale_balance,
							uint256 publicsale_balance,
							uint256 remain_balance);
	event DeliverTokens(address indexed from, address indexed to, uint256 token_amount, uint256 deliver_time, bytes32 hash_id);
	event UpdateMinimumAmount( address indexed updater, uint256 minimumWeiAmount);
	event UpdateReFundAddress( address indexed updater, address indexed refund_address);

	constructor(
		uint256 _openingTime, 
		uint256 _closingTime,
		uint256 _minimum_weiAmount,
		uint256 _rate,
		address _admin_wallet, 
		address _eth_management_wallet,
		address _refund_token_wallet,
		address _cot_sale_wallet,
		WhiteList _whiteList,
		ERC20 _cot,
		Deliver _deliver,
		Bonus _bonus) public
	    Crowdsale(_rate, _eth_management_wallet, _cot)
	    TimedCrowdsale(_openingTime, _closingTime)
	{
		minimum_weiAmount = _minimum_weiAmount;

		admin_wallet = _admin_wallet;
		eth_management_wallet = _eth_management_wallet;
		refund_token_wallet = _refund_token_wallet;
		cot_sale_wallet = _cot_sale_wallet;

		public_opening_time = _openingTime;
		public_closing_time = _closingTime;

		white_list = _whiteList;
		deliver = _deliver;
		bonus = _bonus;

		emit UpdateRate( msg.sender, now,  _rate);
		emit UpdateMinimumAmount(msg.sender, _minimum_weiAmount);
	}

	/**
	* @dev low level token purchase ***DO NOT OVERRIDE***
	* @param _beneficiary Address performing the token purchase
	*/
	function buyTokens(address _beneficiary) onlyWhileOpen whenNotPaused public payable {

		uint256 weiAmount = msg.value;
		_preValidatePurchase(_beneficiary, weiAmount);

		// calculate token amount to be created
		uint256 tokens = _getTokenAmount(weiAmount);

		// update state
		weiRaised = weiRaised.add(weiAmount);

		_processPurchase(_beneficiary, tokens);
		emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

		_updatePurchasingState(_beneficiary, weiAmount);

		_forwardFunds();
		_postValidatePurchase(_beneficiary, weiAmount);
	}

	/**
	* @dev Validation of an incoming purchase. Use require statemens to revert state when conditions are not met. Use super to concatenate validations.
	* @param _beneficiary Address performing the token purchase
	* @param _weiAmount Value in wei involved in the purchase
	*/
	function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
		require(_beneficiary != address(0));
		require(_weiAmount != 0);

		//minimum ether check
		uint256 publicSale_first_stage_endTime = bonus.getPublicSaleFirstStageEndTime();

		//need to check minimum ether
		require(_weiAmount >= minimum_weiAmount);
		
		//owner can not purchase token
		require(_beneficiary != admin_wallet);
		require(_beneficiary != eth_management_wallet);

		//whitelist check
		//whitelist 2-public sale user
		uint8 inWhitelist = white_list.checkList(_beneficiary);

		//if need to check whitelist status
		//0:white listに入ってない, 1:プレセール, 2:パブリックセール, 3:プレミアムセール
		if( white_list.getPublicSaleWhitelistStatus() ){
			require( inWhitelist != 0);
		}

	}

	/**
	* @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
	* @param _beneficiary Address receiving the tokens
	* @param _tokenAmount Number of tokens to be purchased
	*/
	function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {

		//check waiting time date which provided by KVC
		uint256 waiting_time = deliver.getWaitingPlate(_beneficiary);

		require(waiting_time != 0);

		//calculate that when will deliver token to purchaser
		uint256 deliver_date = waiting_time + now;

		//calculate the token + bonus
		uint256 total_token_amount = bonus.getTotalAmount(waiting_time, _tokenAmount);

		//make the unique id
		bytes32 hash_id = keccak256(abi.encodePacked(_beneficiary,now));

        //get total cot sale amount
        uint256 cot_sale_wallet_balance = token.balanceOf(cot_sale_wallet);
        uint256 publicsale_balance = token.balanceOf(address(this));

		uint256 total_cot_amount =  cot_sale_wallet_balance.add(publicsale_balance);
		uint256 expect_pending_balance = pending_balance.add(total_token_amount);
        require(total_cot_amount > expect_pending_balance);
        uint256 remain_cot_amount = total_cot_amount.sub(expect_pending_balance);


		pending_balance = pending_balance.add(total_token_amount);

		require(deliver.pushTokenDeliverPlate(_beneficiary, hash_id, total_token_amount , deliver_date));

		emit PublicsalePurchase(_beneficiary, now, waiting_time, deliver_date, msg.value, _tokenAmount, total_token_amount, hash_id, cot_sale_wallet_balance, publicsale_balance, remain_cot_amount);
	}

	/**
	* @dev called for get pending balance
	*/
	function getPendingBalance() public view returns(uint256){
		return pending_balance; 
	}	

	/**
	* @dev called for update user waiting time
	* @param _users Address 
	* @param _waiting_times 時期申告時間
	* @return A bool that indicates if the operation was successful.
	*/
	function updateWaitingPlate(address[] _users, uint256[] _waiting_times)onlyOwner public returns(bool){

		require(deliver.pushWaitingPlate(_users, _waiting_times));

		return true;		
	}

	/**
	* @dev called for update user deliver suspending status
	* @param _hash_id unique hash id
	* @param _suspending ユーザーのトークン配布禁止フラグ
	* @return A bool that indicates if the operation was successful.
	*/
	function updateDeliverSuspending(bytes32 _hash_id, bool _suspending)onlyOwner public returns(bool){

		require(deliver.updateDeliverSuspending(_hash_id, _suspending));

		return true;		
	}

	/**
	* @dev called for get status of pause.
	*/
	function ispause() public view returns(bool){
		return paused;
	}	

	/**
	* @dev Function update rate
	* @param _newRate rate
	* @return A bool that indicates if the operation was successful.
	*/
	function updateRate(int256 _newRate)onlyOwner public returns(bool){
		require(_newRate >= 1);

		rate = uint256(_newRate);

		emit UpdateRate( msg.sender, now, rate);

		return true;
	}

	/**
	* @dev Function get rate
	* @return A uint256 that indicates if the operation was successful.
	*/
	function getRate() public view returns(uint256){
		return rate;
	}

	/**
	* @dev Function return token back to the admin wallet
	* @return A bool that indicates if the operation was successful.
	*/
	function reFundToken(uint256 _value)onlyOwner public returns (bool){
		token.transfer(refund_token_wallet, _value);

		emit ReFundToken(msg.sender, refund_token_wallet, _value);
	}

	/**
	* @dev Function to update refund address
	* @param _add new refund Address 
	* @return A bool that indicates if the operation was successful.
	*/
	function updateReFundAddress(address _add)onlyOwner public returns (bool){
		refund_token_wallet = _add;

		emit UpdateReFundAddress(msg.sender, _add);
		return true;
	}

	/**
	* @dev called for deliver token
	* @param _beneficiary Address 
	* @param _hash_id unique hash id
	* @return A bool that indicates if the operation was successful.
	*/
	function deliverTokens(address _beneficiary, bytes32 _hash_id)onlyOwner public returns (bool){
		
		// will reject if already delivered token 
		bool already_delivered = deliver.deliverCheck(_hash_id);
		require(already_delivered == false);

		//get the token deliver date 
		uint256 deliver_token_date = deliver.getTokenDeliverDatePlate(_hash_id);
		require(deliver_token_date <= now);

		//get the token amount that need to deliver 
		uint256 deliver_token_amount = deliver.getTokenDeliverPlate(_hash_id);
		require(deliver_token_amount > 0);

		//deliver user should match
		address deliver_user = deliver.getHashMappingAddress(_hash_id);
		require(deliver_user == _beneficiary);

		//get token deliver suspending status
		bool deliver_suspending = deliver.getDeliverSuspending(_hash_id);
		require(!deliver_suspending);

		//get the total pending token amount for this user
		uint256 penging_total_deliver_token_amount = deliver.getPendingDeliverToken(_beneficiary);
		require(penging_total_deliver_token_amount > 0);

		//the remain pending token amount should not less than 0
		uint256 remain_panding_total_deliver_token_amount = penging_total_deliver_token_amount - deliver_token_amount;
		require(remain_panding_total_deliver_token_amount >= 0);

		//deliver token
		token.transfer(_beneficiary, deliver_token_amount);

		//reset data
		require(deliver.resetTokenDeliverPlate(_beneficiary, _hash_id, deliver_token_amount));

		pending_balance = pending_balance.sub(deliver_token_amount);

		emit DeliverTokens(msg.sender, _beneficiary, deliver_token_amount, now, _hash_id);
	}

	/**
	* @dev get admin wallet
	*/
	function getAdminAddress() public view returns(address) {
		return admin_wallet;
	}

	/**
	* @dev get eth management owner wallet
	*/
	function getEtherManagementAddress() public view returns(address) {
		return eth_management_wallet;
	}

	/**
	* @dev get token refund wallet
	*/
	function getReFundAddress() public view returns(address) {
		return refund_token_wallet;
	}

	/**
	* @dev get start date for public sale
	*/
	function getPublicsaleOpeningDate() public view returns(uint256) {
		return public_opening_time;
	}

	/**
	* @dev get end date for public sale
	*/
	function getPublicsaleClosingDate() public view returns(uint256) {
		return public_closing_time;
	}

	/**
	* @dev Function get minimum wei amount
	* @return A uint256 that indicates if the operation was successful.
	*/
	function getMinimumAmount() public view returns(uint256){
		return minimum_weiAmount;
	}

	/**
	* @dev Function update minimum wei amount
	* @return A uint256 that indicates if the operation was successful.
	*/
	function updateMinimumAmount(int256 _new_minimum_weiAmount)onlyOwner public returns(bool){

		require(_new_minimum_weiAmount >= 0);

		minimum_weiAmount = uint256(_new_minimum_weiAmount);

		emit UpdateMinimumAmount( msg.sender, minimum_weiAmount);

		return true;
	}

}