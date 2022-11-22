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