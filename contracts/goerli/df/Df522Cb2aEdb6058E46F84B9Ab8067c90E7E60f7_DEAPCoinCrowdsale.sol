pragma solidity ^0.4.21;


import "openzeppelin-solidity/contracts/ownership/Ownable.sol";


/**
 * @title BatchTransferable
 * @dev Base contract which allows children to run batch transfer token.
 */
contract BatchTransferable is Ownable {
  event BatchTransferStop();

  bool public batchTransferStopped = false;


  /**
   * @dev Modifier to make a function callable only when the contract is do batch transfer token.
   */
  modifier whenBatchTransferNotStopped() {
    require(!batchTransferStopped);
    _;
  }

  /**
   * @dev called by the owner to stop, triggers stopped state
   */
  function batchTransferStop() onlyOwner whenBatchTransferNotStopped public {
    batchTransferStopped = true;
    emit BatchTransferStop();
  }

  /**
   * @dev called to check that can do batch transfer or not
   */
  function isBatchTransferStop() public view returns (bool){
    return batchTransferStopped;
  }

}

pragma solidity ^0.4.18;

import './GroupLockup.sol';
import './ERC223/ERC223Token.sol';
import './ERC223/ERC223ContractInterface.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

contract DEAPCoin is ERC223Token{
	using SafeMath for uint256;

	string public constant name = 'DEAPCOIN';
	string public constant symbol = 'DEP';
	uint8 public constant decimals = 18;
	uint256 public constant INITIAL_SUPPLY = 30000000000 * (10 ** uint256(decimals));
	uint256 public constant INITIAL_SALE_SUPPLY = 12000000000 * (10 ** uint256(decimals));
	uint256 public constant INITIAL_UNSALE_SUPPLY = INITIAL_SUPPLY - INITIAL_SALE_SUPPLY;

	address public owner_wallet;
	address public unsale_owner_wallet;

	GroupLockup public group_lockup;

	event BatchTransferFail(address indexed from, address indexed to, uint256 value, string msg);

	/**
	* @dev Constructor that gives msg.sender all of existing tokens.
	*/
	constructor(address _sale_owner_wallet, address _unsale_owner_wallet, GroupLockup _group_lockup) public {
		group_lockup = _group_lockup;
		owner_wallet = _sale_owner_wallet;
		unsale_owner_wallet = _unsale_owner_wallet;

		mint(owner_wallet, INITIAL_SALE_SUPPLY);
		mint(unsale_owner_wallet, INITIAL_UNSALE_SUPPLY);

		finishMinting();
	}

	/**
	* @dev transfer token for a specified address
	* @param _to The address to transfer to.
	* @param _value The amount to be transferred.
	*/
	function sendTokens(address _to, uint256 _value) onlyOwner public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[owner_wallet]);

		bytes memory empty;
		
		// SafeMath.sub will throw if there is not enough balance.
		balances[owner_wallet] = balances[owner_wallet].sub(_value);
		balances[_to] = balances[_to].add(_value);

	    bool isUserAddress = false;
	    // solium-disable-next-line security/no-inline-assembly
	    assembly {
	      isUserAddress := iszero(extcodesize(_to))
	    }

	    if (isUserAddress == false) {
	      ERC223ContractInterface receiver = ERC223ContractInterface(_to);
	      receiver.tokenFallback(msg.sender, _value, empty);
	    }

		emit Transfer(owner_wallet, _to, _value);
		return true;
	}

	/**
	* @dev transfer token for a specified address
	* @param _to The address to transfer to.
	* @param _value The amount to be transferred.
	*/
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);
		require(_value > 0);

		bytes memory empty;

		bool inLockupList = group_lockup.inLockupList(msg.sender);

		//if user in the lockup list, they can only transfer token after lockup date
		if(inLockupList){
			uint256 lockupTime = group_lockup.getLockupTime(msg.sender);
			require( group_lockup.isLockup(lockupTime) == false );
		}

		// SafeMath.sub will throw if there is not enough balance.
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);

	    bool isUserAddress = false;
	    // solium-disable-next-line security/no-inline-assembly
	    assembly {
	      isUserAddress := iszero(extcodesize(_to))
	    }

	    if (isUserAddress == false) {
	      ERC223ContractInterface receiver = ERC223ContractInterface(_to);
	      receiver.tokenFallback(msg.sender, _value, empty);
	    }

		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	/**
	* @dev transfer token for a specified address
	* @param _to The address to transfer to.
	* @param _value The amount to be transferred.
	* @param _data The data info.
	*/
	function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);
		require(_value > 0);

		bool inLockupList = group_lockup.inLockupList(msg.sender);

		//if user in the lockup list, they can only transfer token after lockup date
		if(inLockupList){
			uint256 lockupTime = group_lockup.getLockupTime(msg.sender);
			require( group_lockup.isLockup(lockupTime) == false );
		}

		// SafeMath.sub will throw if there is not enough balance.
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);

	    bool isUserAddress = false;
	    // solium-disable-next-line security/no-inline-assembly
	    assembly {
	      isUserAddress := iszero(extcodesize(_to))
	    }

	    if (isUserAddress == false) {
	      ERC223ContractInterface receiver = ERC223ContractInterface(_to);
	      receiver.tokenFallback(msg.sender, _value, _data);
	    }

	    emit Transfer(msg.sender, _to, _value);
		emit TransferERC223(msg.sender, _to, _value, _data);
		return true;
	}	


	/**
	* @dev transfer token to mulitipule user
	* @param _from which wallet's token will be taken.
	* @param _users The address list to transfer to.
	* @param _values The amount list to be transferred.
	*/
	function batchTransfer(address _from, address[] _users, uint256[] _values) onlyOwner public returns (bool) {

		address to;
		uint256 value;
		bool isUserAddress;
		bool canTransfer;
		string memory transferFailMsg;

		for(uint i = 0; i < _users.length; i++) {

			to = _users[i];
			value = _values[i];
			isUserAddress = false;
			canTransfer = false;
			transferFailMsg = "";

			// can not send token to contract address
		    //コントラクトアドレスにトークンを発送できない検証
		    assembly {
		      isUserAddress := iszero(extcodesize(to))
		    }

		    //data check
			if(!isUserAddress){
				transferFailMsg = "try to send token to contract";
			}else if(value <= 0){
				transferFailMsg = "try to send wrong token amount";
			}else if(to == address(0)){
				transferFailMsg = "try to send token to empty address";
			}else if(value > balances[_from]){
				transferFailMsg = "token amount is larger than giver holding";
			}else{
				canTransfer = true;
			}

			if(canTransfer){
			    balances[_from] = balances[_from].sub(value);
			    balances[to] = balances[to].add(value);
			    emit Transfer(_from, to, value);
			}else{
				emit BatchTransferFail(_from, to, value, transferFailMsg);
			}

        }

        return true;
	}
}

pragma solidity ^0.4.18;

import './WhiteList.sol';
import './DEAPCoin.sol';
import './SaleInfo.sol';
import './GroupLockup.sol';
import './BatchTransferable.sol';
import 'openzeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import 'openzeppelin-solidity/contracts/lifecycle/Pausable.sol';

contract DEAPCoinCrowdsale is TimedCrowdsale, Ownable, Pausable, BatchTransferable{
	using SafeMath for uint256;

	address public admin_wallet; //wallet to controll system
	address public sale_owner_wallet; 
	address public unsale_owner_wallet;
	address public eth_management_wallet; //wallet to reveive eth

	uint256 public minimum_weiAmount;

	DEAPCoin public deap_token;
	SaleInfo public sale_info;
	WhiteList public white_list;
	GroupLockup public group_lockup;

	event PresalePurchase(address indexed purchaser, uint256 value);
	event PublicsalePurchase(address indexed purchaser, uint256 value, uint256 amount, uint256 rate);
	event UpdateRate(address indexed updater, uint256 rate);
	event UpdateMinimumAmount( address indexed updater, uint256 minimumWeiAmount);
	event GiveToken(address indexed purchaser, uint256 amount, uint256 lockupTime);

	constructor(
		uint256 _openingTime, 
		uint256 _closingTime,
		uint256 _rate,
		uint256 _minimum_weiAmount,
		address _admin_wallet, 
		address _sale_owner_wallet, 
		address _unsale_owner_wallet, 
		address _eth_management_wallet,
		DEAPCoin _deap , 
		SaleInfo _sale_info,
		WhiteList _whiteList, 
		GroupLockup _groupLockup) public
	    Crowdsale(_rate, _eth_management_wallet, _deap)
	    TimedCrowdsale(_openingTime, _closingTime)
	{
		admin_wallet = _admin_wallet;
		sale_owner_wallet = _sale_owner_wallet;
		unsale_owner_wallet = _unsale_owner_wallet;
		eth_management_wallet = _eth_management_wallet;
		deap_token = _deap;
		sale_info = _sale_info;
		white_list = _whiteList;
		group_lockup = _groupLockup;
		minimum_weiAmount = _minimum_weiAmount;

		emit UpdateRate( msg.sender, _rate);
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
		require(_weiAmount >= minimum_weiAmount);

		//owner can not purchase token
		require(_beneficiary != admin_wallet);
		require(_beneficiary != sale_owner_wallet);
		require(_beneficiary != unsale_owner_wallet);
		require(_beneficiary != eth_management_wallet);

		require( sale_info.inPresalePeriod() || sale_info.inPublicsalePeriod() );

		//whitelist check
		//whitelist status:1-presale user, 2-public sale user
		uint8 inWhitelist = white_list.checkList(_beneficiary);

		if(sale_info.inPresalePeriod()){
			//if need to check whitelist status in presale period
			if( white_list.getPresaleWhitelistStatus() ){
				require( inWhitelist == 1);
			}
		}else{
			//if need to check whitelist status in public sale period
			if( white_list.getPublicSaleWhitelistStatus() ){
				require( (inWhitelist == 1) || (inWhitelist == 2) );
			}
		}

	}

	/**
	* @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
	* @param _beneficiary Address performing the token purchase
	* @param _tokenAmount Number of tokens to be emitted
	*/
	function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {

		//will not send token directly when purchaser purchase the token in presale 
		if( sale_info.inPresalePeriod() ){
			emit PresalePurchase( _beneficiary, msg.value );
		}else{
			require(deap_token.sendTokens(_beneficiary, _tokenAmount));
			emit PublicsalePurchase( _beneficiary, msg.value, _tokenAmount, rate);
		}

	}

	/**
	* @dev send token and set token lockup status to specific user
	*     file format:
	*		[
	*	      [<address>, <token amount>, <lockup time>],
	*	      [<address>, <token amount>, <lockup time>],...
	*	    ]
	* @param _beneficiary Address 
	* @param _tokenAmount token amount
	* @param _lockupTime uint256 this address's lockup time
	* @return A bool that indicates if the operation was successful.
	*/
	function giveToken(address _beneficiary, uint256 _tokenAmount, uint256 _lockupTime) onlyOwner public returns (bool){
		require(_beneficiary != address(0));

		require(_tokenAmount > 0);

		if(_lockupTime != 0){
			//add this account in to lockup list
			require(updateLockupList(_beneficiary, _lockupTime));
		}

		require(deap_token.sendTokens(_beneficiary, _tokenAmount));

		emit GiveToken(_beneficiary, _tokenAmount, _lockupTime);

		return true;
	}

	/**
	* @dev send token to mulitple user
	* @param _from token provider address 
	* @param _users user address list
	* @param _values the token amount list that want to deliver
	* @return A bool the operation was successful.
	*/
	function batchTransfer(address _from, address[] _users, uint256[] _values) onlyOwner whenBatchTransferNotStopped public returns (bool){
		require(_users.length > 0 && _values.length > 0 && _users.length == _values.length, "list error");

		require(_from != address(0), "token giver wallet is not the correct address");

		deap_token.batchTransfer(_from, _users, _values);
		return true;
	}

	/**
	* @dev set lockup status to mulitple user
	* @param _users user address list
	* @param _lockup_dates uint256 user lockup time 
	* @return A bool the operation was successful.
	*/
	function batchUpdateLockupList( address[] _users, uint256[] _lockup_dates) onlyOwner public returns (bool){
		require(_users.length > 0 && _lockup_dates.length > 0 && _users.length == _lockup_dates.length, "list error");

		address user;
		uint256 lockup_date;

		for(uint i = 0; i < _users.length; i++) {
			user = _users[i];
			lockup_date = _lockup_dates[i];

            updateLockupList(user, lockup_date);
        }		

		return true;
	}

	/**
	* @dev Function update lockup status for purchaser
	* @param _add address
	* @param _lockup_date uint256 this user's lockup time
	* @return A bool that indicates if the operation was successful.
	*/
	function updateLockupList(address _add, uint256 _lockup_date) onlyOwner public returns (bool){
		
		return group_lockup.updateLockupList(_add, _lockup_date);
	}	

	/**
	* @dev Function update lockup time
	* @param _old_lockup_date uint256
	* @param _new_lockup_date uint256
	* @return A bool that indicates if the operation was successful.
	*/
	function updateLockupTime(uint256 _old_lockup_date, uint256 _new_lockup_date) onlyOwner public returns (bool){
		
		return group_lockup.updateLockupTime(_old_lockup_date, _new_lockup_date);
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

		emit UpdateRate( msg.sender, rate);

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

pragma solidity ^0.4.18;

contract ERC223ContractInterface{
  function tokenFallback(address from_, uint256 value_, bytes data_) external;
}

pragma solidity ^0.4.18;

import "openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol";

contract ERC223Token is MintableToken{
  function transfer(address to, uint256 value, bytes data) public returns (bool);
  event TransferERC223(address indexed from, address indexed to, uint256 value, bytes data);
}

pragma solidity ^0.4.18;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

contract GroupLockup is Ownable{
	using SafeMath for uint256;

	mapping(address => uint256) public lockup_list; //users lockup list
	mapping(uint256 => bool) public lockup_list_flag;
	address[] public user_list; //users address list

	event UpdateLockupList(address indexed owner, address indexed user_address, uint256 lockup_date);
	event UpdateLockupTime(address indexed owner, uint256 indexed old_lockup_date, uint256 new_lockup_date);
	event LockupTimeList(uint256 indexed lockup_date, bool active);

	/**
	* @dev Function to get lockup list
	* @param user_address address 
	* @return A uint256 that indicates if the operation was successful.
	*/
	function getLockupTime(address user_address)public view returns (uint256){
		return lockup_list[user_address];
	}

	/**
	* @dev Function to check token locked date that is reach or not
	* @param lockup_date uint256 
	* @return A bool that indicates if the operation was successful.
	*/
	function isLockup(uint256 lockup_date) public view returns(bool){
		return (now < lockup_date);
	}

	/**
	* @dev Function get user's lockup status
	* @param user_address address
	* @return A bool that indicates if the operation was successful.
	*/
	function inLockupList(address user_address)public view returns(bool){
		if(lockup_list[user_address] == 0){
			return false;
		}
		return true;
	}

	/**
	* @dev Function update lockup status for purchaser, if user in the lockup list, they can only transfer token after lockup date
	* @param user_address address
	* @param lockup_date uint256 this user's token time
	* @return A bool that indicates if the operation was successful.
	*/
	function updateLockupList(address user_address, uint256 lockup_date)onlyOwner public returns(bool){
		if(lockup_date == 0){
			delete lockup_list[user_address];

			for(uint256 user_list_index = 0; user_list_index < user_list.length; user_list_index++) {
				if(user_list[user_list_index] == user_address){
					delete user_list[user_list_index];
					break;
				}
			}
		}else{
			bool user_is_exist = inLockupList(user_address);

			if(!user_is_exist){
				user_list.push(user_address);
			}

			lockup_list[user_address] = lockup_date;

			//insert lockup time into lockup time list, if this lockup time is the new one
			if(!lockup_list_flag[lockup_date]){
				lockup_list_flag[lockup_date] = true;
				emit LockupTimeList(lockup_date, true);
			}
			
		}
		emit UpdateLockupList(msg.sender, user_address, lockup_date);

		return true;
	}

	/**
	* @dev Function update lockup time
	* @param old_lockup_date uint256 old group lockup time
	* @param new_lockup_date uint256 new group lockup time
	* @return A bool that indicates if the operation was successful.
	*/
	function updateLockupTime(uint256 old_lockup_date, uint256 new_lockup_date)onlyOwner public returns(bool){
		require(old_lockup_date != 0);
		require(new_lockup_date != 0);
		require(new_lockup_date != old_lockup_date);

		address user_address;
		uint256 user_lockup_time;

		//update the user's lockup time who was be setted as old lockup time
		for(uint256 user_list_index = 0; user_list_index < user_list.length; user_list_index++) {
			if(user_list[user_list_index] != 0){
				user_address = user_list[user_list_index];
				user_lockup_time = getLockupTime(user_address);
				if(user_lockup_time == old_lockup_date){
					lockup_list[user_address] = new_lockup_date;
					emit UpdateLockupList(msg.sender, user_address, new_lockup_date);
				}
			}
		}

		//delete the old lockup time from lockup time list, if this old lockup time is existing in the lockup time list
		if(lockup_list_flag[old_lockup_date]){
			lockup_list_flag[old_lockup_date] = false;
			emit LockupTimeList(old_lockup_date, false);
		}

		//insert lockup time into lockup time list, if this lockup time is the new one
		if(!lockup_list_flag[new_lockup_date]){
			lockup_list_flag[new_lockup_date] = true;
			emit LockupTimeList(new_lockup_date, true);
		}

		emit UpdateLockupTime(msg.sender, old_lockup_date, new_lockup_date);
		return true;
	}
}

pragma solidity ^0.4.18;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

contract SaleInfo{
	using SafeMath for uint256;

	uint256 public privateOpeningTime;
	uint256 public privateClosingTime;
	uint256 public publicOpeningTime;
	uint256 public publicClosingTime;
	address public admin_wallet;
	address public sale_owner_wallet;
	address public unsale_owner_wallet;
	address public eth_management_wallet;

	constructor(
		uint256 _privateOpeningTime, uint256 _privateClosingTime,
		uint256 _publicOpeningTime, uint256 _publicClosingTime,
		address _admin_wallet, address _sale_owner_wallet, 
		address _unsale_owner_wallet, address _eth_management_wallet ) public
	{
		privateOpeningTime = _privateOpeningTime;
		privateClosingTime = _privateClosingTime;
		publicOpeningTime = _publicOpeningTime;
		publicClosingTime = _publicClosingTime;
		admin_wallet = _admin_wallet;
		sale_owner_wallet = _sale_owner_wallet;
		unsale_owner_wallet = _unsale_owner_wallet;
		eth_management_wallet = _eth_management_wallet;
	}

	/**
	* @dev get admin wallet
	*/
	function getAdminAddress() public view returns(address) {
		return admin_wallet;
	}

	/**
	* @dev get owner wallet
	*/
	function getSaleOwnerAddress() public view returns(address) {
		return sale_owner_wallet;
	}

	/**
	* @dev get unsale owner wallet
	*/
	function getUnsaleOwnerAddress() public view returns(address) {
		return unsale_owner_wallet;
	}

	/**
	* @dev get eth management owner wallet
	*/
	function getEtherManagementAddress() public view returns(address) {
		return eth_management_wallet;
	}

	/**
	* @dev get start date for presale
	*/
	function getPresaleOpeningDate() public view returns(uint256) {
		return privateOpeningTime;
	}

	/**
	* @dev get end date for presale
	*/
	function getPresaleClosingDate() public view returns(uint256) {
		return privateClosingTime;
	}

	/**
	* @dev get start date for public sale
	*/
	function getPublicsaleOpeningDate() public view returns(uint256) {
		return publicOpeningTime;
	}

	/**
	* @dev get end date for public sale
	*/
	function getPublicsaleClosingDate() public view returns(uint256) {
		return publicClosingTime;
	}	

	/**
	* @dev current time is in presale period or not
	*/
	function inPresalePeriod() public view returns(bool){
		return ( (now >= privateOpeningTime) && (now <= privateClosingTime) );
	}

	/**
	* @dev current time is in public sale period or not
	*/
	function inPublicsalePeriod() public view returns(bool){
		return ( (now >= publicOpeningTime) && (now <= publicClosingTime) );
	}	
}

pragma solidity ^0.4.18;
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

contract WhiteList is Ownable{


	mapping(address => uint8) public whitelist;
	bool public presale_need_whitelist = true;
	bool public publicsale_need_whitelist = true;

	event ImportList(address indexed owner, address[] users, uint8 flag);
	event UpdatePresaleWhitelistStatus(address indexed owner, bool flag);
	event UpdatePublicSaleWhitelistStatus(address indexed owner, bool flag);

  	/**
	* @dev Function to import user's address into whitelist, only user who in the whitelist can purchase token.
	*      Whitelistにユーザーアドレスを記録。sale期間に、Whitelistに記録したユーザーたちしかトークンを購入できない
	* @param _users The address list that can purchase token when sale period.
	* @param _flag The flag for record different lv user, 1: pre sale user, 2: public sale user.
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
	* @dev Function get whitelist able status in presale 
	* @return A bool that indicates if the operation was successful.
	*/
	function getPresaleWhitelistStatus()public view returns(bool){
		return presale_need_whitelist;
	}

  	/**
	* @dev Function get whitelist able status in public sale 
	* @return A bool that indicates if the operation was successful.
	*/
	function getPublicSaleWhitelistStatus()public view returns(bool){
		return publicsale_need_whitelist;
	}	

  	/**
	* @dev Function update whitelist able status in presale 
	* @param _flag bool whitelist status
	* @return A bool that indicates if the operation was successful.
	*/
	function updatePresaleWhitelistStatus(bool _flag) onlyOwner public returns(bool){
		presale_need_whitelist = _flag;

		emit UpdatePresaleWhitelistStatus(msg.sender, _flag);

		return true;
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

pragma solidity ^0.4.21;

import "../token/ERC20/ERC20.sol";
import "../math/SafeMath.sol";


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

  // How many token units a buyer gets per wei
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
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public {
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
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    // optional override
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    // optional override
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

pragma solidity ^0.4.21;

import "../../math/SafeMath.sol";
import "../Crowdsale.sol";


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
  function TimedCrowdsale(uint256 _openingTime, uint256 _closingTime) public {
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
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

pragma solidity ^0.4.21;


import "../ownership/Ownable.sol";


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

pragma solidity ^0.4.21;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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

pragma solidity ^0.4.21;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

pragma solidity ^0.4.21;


import "./ERC20Basic.sol";
import "../../math/SafeMath.sol";


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

pragma solidity ^0.4.21;

import "./ERC20Basic.sol";


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.4.21;


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

pragma solidity ^0.4.21;

import "./StandardToken.sol";
import "../../ownership/Ownable.sol";


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

pragma solidity ^0.4.21;

import "./BasicToken.sol";
import "./ERC20.sol";


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}