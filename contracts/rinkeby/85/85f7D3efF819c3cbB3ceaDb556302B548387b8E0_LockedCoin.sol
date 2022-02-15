// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.4.11;

import "./ERC777.sol";

//----------------------------------------------------------------------------------

contract LockedCoin is ERC777 {

	Lockable public coin; //MASTER COIN
	
	mapping(address => mapping(bytes32 => uint256)) private _lockedAmmountByHash;
	mapping(address => mapping(bytes32 => uint256)) private _lockedAmmountByHashOfSender;
	mapping(address => mapping(bytes32 => address)) private _holderToLockerByHash;

    constructor () public ERC777("LockedCoin", "LdC", new address[](0)) {
		coin = Lockable(msg.sender); 
    }
	
	function balanceByHash(address _to, bytes32 _hash) public view returns (uint256 amount){
		return _lockedAmmountByHash[_to][_hash];
	}
	
	function burnByHash(address _to, bytes32 _hash) public returns (uint256 amount){
		require(msg.sender == address(coin), "Only available for master coin");
		require(_lockedAmmountByHash[_to][_hash] > 0, "There is no amount locked with the given hash");
		uint256 _amount = _lockedAmmountByHash[_to][_hash];
		_burn(_to, _amount, "", "");
		_lockedAmmountByHash[_to][_hash] = 0;
		_lockedAmmountByHashOfSender[_holderToLockerByHash[_to][_hash]][_hash] = 0;
		_holderToLockerByHash[_to][_hash] = address(0);
		
		return _amount;
	}
	
	function burnByHash(address _from, address _to, bytes32 _hash) public returns (uint256 amount){
		require(msg.sender == address(coin), "Only available for master coin");
		require(_lockedAmmountByHash[_to][_hash] > 0, "No amount locked with this hash");
		require(_holderToLockerByHash[_to][_hash] == _from, "Not locked by this address");
		uint256 _amount = _lockedAmmountByHash[_to][_hash];
		_burn(_to, _amount, "", "");
		_lockedAmmountByHash[_to][_hash] = 0;
		_lockedAmmountByHashOfSender[_from][_hash] = 0;
		_holderToLockerByHash[_to][_hash] = address(0); 
		
		return _amount;
	}
	
	function lockerOf(address _to, bytes32 _hash) public view returns (address _from){
		return _holderToLockerByHash[_to][_hash];
	}
	
	function lockedAmount(address _from, bytes32 hash) public view returns (uint256 amount){
		return _lockedAmmountByHashOfSender[_from][hash];
	}
	
	function mintByHash(address _to, uint256 _amount, bytes32 _hash, address _from) public {
		require(msg.sender == address(coin), "Only available for master coin");
		require(_lockedAmmountByHash[_to][_hash] == 0, "There is already amount locked with the same hash");
		_mint(_to, _amount, "", "");
		_lockedAmmountByHash[_to][_hash] = _amount;
		_lockedAmmountByHashOfSender[_from][_hash] = _amount;
		_holderToLockerByHash[_to][_hash] = _from;
	}
	
	function reclaim(address _to, string unlockerPhrase) public {
		bytes32 hash = keccak256(bytes(unlockerPhrase));
		require(_holderToLockerByHash[_to][hash] == msg.sender, "Not locked by this address");
		uint256 amount = burnByHash(msg.sender, _to, hash);
		coin.reclaimByLockedCoinContract(msg.sender, _to, hash);
	}
	
	function unlock(string unlockerPhrase) public {
		bytes32 hash = keccak256(bytes(unlockerPhrase));
		coin.unlockByLockedCoinContract(msg.sender, hash);
	}
	
	//TRANSFERS ONLY ALLOWED FROM MASTER COIN
    function _beforeTokenTransfer(address operator, address from, address to, uint256 amount) internal {
		require(msg.sender == address(coin), "Unlock to transferable coin");
	}
}

//----------------------------------------------------------------------------------

contract Lockable is ERC777 {

	LockedCoin public lockedCoin;
	
	uint256 public lockedSupply;
	
	mapping(address => uint256) private _lockedBalances;

	constructor () public ERC777("Lockable", "LC", new address[](0)) {
        _mint(msg.sender, 1000000 * 10 ** 18, "", "");
		lockedCoin = new LockedCoin();		
	}
	
	function lock(address _to, uint256 amount, bytes32 hash) public {
		uint256 fromBalance = balanceOf(msg.sender);
        require(fromBalance >= amount, "ERC777: amount exceeds balance");
		lockedCoin.mintByHash(_to, amount, hash, msg.sender);
		_send(msg.sender, address(this), amount, "", "", false);
		lockedSupply += amount;
		_lockedBalances[_to] += amount;
		require(lockedSupply >= amount, "Math is not ok");
		require(_lockedBalances[_to] == lockedCoin.balanceOf(_to), "Balances did not sync");
	}
	
	function lockedAmount(address _from, bytes32 hash) public view returns (uint256 amount){
		return lockedCoin.lockedAmount(_from, hash);
	}
	
	function lockedBalanceOf(address account) public view returns (uint256){
		return _lockedBalances[account];
	}
	
	function operatorLock(address _from, address _to, uint256 amount, bytes32 hash, bytes data, bytes operatorData) external {
        require(isOperatorFor(_msgSender(), _from), "ERC777: caller is not an operator for holder");
		uint256 fromBalance = balanceOf(_from);
        require(fromBalance >= amount, "ERC777: amount exceeds balance");
		lockedCoin.mintByHash(_to, amount, hash, _from);
		_send(_from, address(this), amount, data, operatorData, true);
		lockedSupply += amount;
		_lockedBalances[_to] += amount;
		require(lockedSupply >= amount, "Math is not ok");
		require(_lockedBalances[_to] == lockedCoin.balanceOf(_to), "Balances did not sync");
    }
	
	function operatorReclaim(address _from, address _to, string unlockerPhrase, bytes data, bytes operatorData) external {
		bytes32 hash = keccak256(bytes(unlockerPhrase));
        require(isOperatorFor(_msgSender(), _from), "ERC777: caller is not an operator for holder");
		require(msg.sender != _from);
		uint256 amount = lockedCoin.burnByHash(_from, _to, hash);
		require(lockedSupply >= amount, "Balances are not in sync");
		require(_lockedBalances[_to] >= amount, "Balances are not in sync");
		_send(address(this), _from, amount, data, operatorData, true);
		lockedSupply -= amount;
		_lockedBalances[_to] -= amount;
		require(_lockedBalances[_to] == lockedCoin.balanceOf(_to), "Balances did not sync");
	}
	
	function operatorUnlock(address _to, string unlockerPhrase, bytes data, bytes operatorData) external {
		bytes32 hash = keccak256(bytes(unlockerPhrase));
        require(isOperatorFor(_msgSender(), lockedCoin.lockerOf(_to, hash)), "ERC777: caller is not an operator for holder");
		uint256 amount = lockedCoin.burnByHash(_to, hash);
		require(lockedSupply >= amount, "Balances are not in sync");
		require(_lockedBalances[_to] >= amount, "Balances are not in sync");
		_send(address(this), _to, amount, data, operatorData, true);
		lockedSupply -= amount;	
		_lockedBalances[_to] -= amount;
		require(_lockedBalances[_to] == lockedCoin.balanceOf(_to), "Balances did not sync");
	}
	
	function reclaim(address _to, string unlockerPhrase) public {
		bytes32 hash = keccak256(bytes(unlockerPhrase));
		uint256 amount = lockedCoin.burnByHash(msg.sender, _to, hash);
		require(lockedSupply >= amount, "Balances are not in sync");
		require(_lockedBalances[_to] >= amount, "Balances are not in sync");
		_send(address(this), msg.sender, amount, "", "", false);
		lockedSupply -= amount;
		_lockedBalances[_to] -= amount;
		require(_lockedBalances[_to] == lockedCoin.balanceOf(_to), "Balances did not sync");		
	}
	
	function reclaimByLockedCoinContract(address _from, address _to, bytes32 hash) public {
		require(msg.sender == address(lockedCoin), "Only avaliable for the locked coin contract");
		uint256 amount = lockedCoin.burnByHash(_from, _to, hash);
		require(lockedSupply >= amount, "Balances are not in sync");
		require(_lockedBalances[_to] >= amount, "Balances are not in sync");
		_send(address(this), _from, amount, "", "", false);
		lockedSupply -= amount;
		_lockedBalances[_to] -= amount;
		require(_lockedBalances[_to] == lockedCoin.balanceOf(_to), "Balances did not sync");	
	}
	
	function unlock(string unlockerPhrase) public {
		bytes32 hash = keccak256(bytes(unlockerPhrase));
		uint256 amount = lockedCoin.burnByHash(msg.sender, hash);
		require(lockedSupply >= amount, "Balances are not in sync");
		require(_lockedBalances[msg.sender] >= amount, "Balances are not in sync");
		_send(address(this), msg.sender, amount, "", "", false);
		lockedSupply -= amount;	
		_lockedBalances[msg.sender] -= amount;
		require(_lockedBalances[msg.sender] == lockedCoin.balanceOf(msg.sender), "Balances did not sync");
	}
	
	function unlockByLockedCoinContract(address _to, bytes32 hash) public {
		require(msg.sender == address(lockedCoin), "Only avaliable for the locked coin contract");
		uint256 amount = lockedCoin.burnByHash(_to, hash);
		require(lockedSupply >= amount, "Balances are not in sync");
		require(_lockedBalances[_to] >= amount, "Balances are not in sync");
		_send(address(this), _to, amount, "", "", false);
		lockedSupply -= amount;	
		_lockedBalances[_to] -= amount;
		require(_lockedBalances[_to] == lockedCoin.balanceOf(_to), "Balances did not sync");
	}
}