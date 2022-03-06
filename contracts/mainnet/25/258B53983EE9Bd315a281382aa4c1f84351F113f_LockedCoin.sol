// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "./ERC777.sol";

//----------------------------------------------------------------------------------

contract LockedCoin is ERC777 {

    Lockable public coin; //MASTER COIN
    string public uri="https://www.epigeon.org/lockable";
    
    mapping(address => mapping(bytes32 => uint256)) private _lockedAmmountByHash;
    mapping(address => mapping(bytes32 => uint256)) private _lockedAmmountByHashOfSender;
    mapping(address => mapping(bytes32 => address)) private _holderToLockerByHash;

    constructor () ERC777("LockedCoin", "LdC", new address[](0)) {
        coin = Lockable(msg.sender);
    }
    
    function balanceByHash(address to, bytes32 hash) public view returns (uint256 amount){
        return _lockedAmmountByHash[to][hash];
    }
    
    function burnByHash(address to, bytes32 hash) public returns (uint256 amount){
        require(msg.sender == address(coin), "Only available for master coin");
        require(_lockedAmmountByHash[to][hash] > 0, "No amount locked with given hash");
        uint256 lockedValue = _lockedAmmountByHash[to][hash];
        _burn(to, lockedValue, "", "");
        _lockedAmmountByHash[to][hash] = 0;
        _lockedAmmountByHashOfSender[_holderToLockerByHash[to][hash]][hash] = 0;
        _holderToLockerByHash[to][hash] = address(0);
        
        return lockedValue;
    }
    
    function burnByHash(address from, address to, bytes32 hash) public returns (uint256 amount){
        require(msg.sender == address(coin), "Only available for master coin");
        require(_lockedAmmountByHash[to][hash] > 0, "No amount locked with given hash");
        require(_holderToLockerByHash[to][hash] == from, "Not locked by this address");
        uint256 lockedValue = _lockedAmmountByHash[to][hash];
        _burn(to, lockedValue, "", "");
        _lockedAmmountByHash[to][hash] = 0;
        _lockedAmmountByHashOfSender[from][hash] = 0;
        _holderToLockerByHash[to][hash] = address(0); 
        
        return lockedValue;
    }
    
    function getOwner() public view returns (address owner) {
        return coin.getOwner();
    }
    
    function lockerOf(address to, bytes32 hash) public view returns (address from){
        return _holderToLockerByHash[to][hash];
    }
    
    function lockedAmount(address from, bytes32 hash) public view returns (uint256 amount){
        return _lockedAmmountByHashOfSender[from][hash];
    }
    
    function mintByHash(address to, uint256 amount, bytes32 hash, address from) public {
        require(msg.sender == address(coin), "Only available for master coin");
        require(_lockedAmmountByHash[to][hash] == 0, "Amount locked with the same hash");
        _mint(to, amount, "", "");
        _lockedAmmountByHash[to][hash] = amount;
        _lockedAmmountByHashOfSender[from][hash] = amount;
        _holderToLockerByHash[to][hash] = from;
    }
    
    function reclaim(address to, string memory unlockerPhrase) public {
        bytes32 hash = keccak256(bytes(unlockerPhrase));
        require(_holderToLockerByHash[to][hash] == msg.sender, "Not locked by this address");
        burnByHash(msg.sender, to, hash);
        coin.reclaimByLockedCoinContract(msg.sender, to, hash);
    }
    
    function setUri(string memory url) public {
        require(msg.sender == coin.getOwner());
        uri = url;
    }
    
    function unlock(string memory unlockerPhrase) public {
        bytes32 hash = keccak256(bytes(unlockerPhrase));
        coin.unlockByLockedCoinContract(msg.sender, hash);
    }
    
    //TRANSFERS ONLY ALLOWED FROM MASTER COIN
    function _beforeTokenTransfer(address operator, address from, address to, uint256 amount) internal override {
        require(msg.sender == address(coin), "Unlock to transferable coin");
        super._beforeTokenTransfer(operator, from, to, amount);
    }
}

//----------------------------------------------------------------------------------

contract Lockable is ERC777 {

    LockedCoin public lockedCoin;
    address private _owner;
    
    uint256 public lockedSupply;
    mapping(address => uint256) private _lockedBalances;

    constructor () ERC777("Lockable", "LC", new address[](0)) {
        _owner = msg.sender;
        _mint(msg.sender, 10000000 * 10 ** 18, "", "");
        lockedCoin = new LockedCoin();
    }
    
    function getOwner() public view returns (address owner) {
        return _owner;
    }
    
    function lock(address to, uint256 amount, bytes32 hash) public {
        uint256 fromBalance = balanceOf(msg.sender);
        require(fromBalance >= amount, "ERC777: amount exceeds balance");
        lockedCoin.mintByHash(to, amount, hash, msg.sender);
        _send(msg.sender, address(this), amount, "", "", false);
        lockedSupply += amount;
        _lockedBalances[to] += amount;
        require(lockedSupply >= amount, "Math is not ok");
        require(_lockedBalances[to] == lockedCoin.balanceOf(to), "Balances did not sync");
    }
    
    function lockedAmount(address from, bytes32 hash) public view returns (uint256 amount){
        return lockedCoin.lockedAmount(from, hash);
    }
    
    function lockedBalanceOf(address account) public view returns (uint256){
        return _lockedBalances[account];
    }
    
    function operatorLock(address from, address to, uint256 amount, bytes32 hash, bytes memory data, bytes memory operatorData) external {
        require(isOperatorFor(_msgSender(), from), "ERC777: caller is not an operator for holder");
        uint256 fromBalance = balanceOf(from);
        require(fromBalance >= amount, "ERC777: amount exceeds balance");
        lockedCoin.mintByHash(to, amount, hash, from);
        _send(from, address(this), amount, data, operatorData, true);
        lockedSupply += amount;
        _lockedBalances[to] += amount;
        require(lockedSupply >= amount, "Math is not ok");
        require(_lockedBalances[to] == lockedCoin.balanceOf(to), "Balances did not sync");
    }
    
    function operatorReclaim(address from, address to, string memory unlockerPhrase, bytes memory data, bytes memory operatorData) external {
        bytes32 hash = keccak256(bytes(unlockerPhrase));
        require(isOperatorFor(_msgSender(), from), "ERC777: caller is not an operator for holder");
        require(msg.sender != from);
        uint256 amount = lockedCoin.burnByHash(from, to, hash);
        require(lockedSupply >= amount, "Balances are not in sync");
        require(_lockedBalances[to] >= amount, "Balances are not in sync");
        _send(address(this), from, amount, data, operatorData, true);
        lockedSupply -= amount;
        _lockedBalances[to] -= amount;
        require(_lockedBalances[to] == lockedCoin.balanceOf(to), "Balances did not sync");
    }
    
    function operatorUnlock(address to, string memory unlockerPhrase, bytes memory data, bytes memory operatorData) external {
        bytes32 hash = keccak256(bytes(unlockerPhrase));
        require(isOperatorFor(_msgSender(), lockedCoin.lockerOf(to, hash)), "ERC777: caller is not an operator for holder");
        uint256 amount = lockedCoin.burnByHash(to, hash);
        require(lockedSupply >= amount, "Balances are not in sync");
        require(_lockedBalances[to] >= amount, "Balances are not in sync");
        _send(address(this), to, amount, data, operatorData, true);
        lockedSupply -= amount; 
        _lockedBalances[to] -= amount;
        require(_lockedBalances[to] == lockedCoin.balanceOf(to), "Balances did not sync");
    }
    
    function reclaim(address to, string memory unlockerPhrase) public {
        bytes32 hash = keccak256(bytes(unlockerPhrase));
        uint256 amount = lockedCoin.burnByHash(msg.sender, to, hash);
        require(lockedSupply >= amount, "Balances are not in sync");
        require(_lockedBalances[to] >= amount, "Balances are not in sync");
        _send(address(this), msg.sender, amount, "", "", false);
        lockedSupply -= amount;
        _lockedBalances[to] -= amount;
        require(_lockedBalances[to] == lockedCoin.balanceOf(to), "Balances did not sync");        
    }
    
    function reclaimByLockedCoinContract(address from, address to, bytes32 hash) public {
        require(msg.sender == address(lockedCoin), "Only avaliable for the locked coin contract");
        uint256 amount = lockedCoin.burnByHash(from, to, hash);
        require(lockedSupply >= amount, "Balances are not in sync");
        require(_lockedBalances[to] >= amount, "Balances are not in sync");
        _send(address(this), from, amount, "", "", false);
        lockedSupply -= amount;
        _lockedBalances[to] -= amount;
        require(_lockedBalances[to] == lockedCoin.balanceOf(to), "Balances did not sync");    
    }
    
    function unlock(string memory unlockerPhrase) public {
        bytes32 hash = keccak256(bytes(unlockerPhrase));
        uint256 amount = lockedCoin.burnByHash(msg.sender, hash);
        require(lockedSupply >= amount, "Balances are not in sync");
        require(_lockedBalances[msg.sender] >= amount, "Balances are not in sync");
        _send(address(this), msg.sender, amount, "", "", false);
        lockedSupply -= amount; 
        _lockedBalances[msg.sender] -= amount;
        require(_lockedBalances[msg.sender] == lockedCoin.balanceOf(msg.sender), "Balances did not sync");
    }
    
    function unlockByLockedCoinContract(address to, bytes32 hash) public {
        require(msg.sender == address(lockedCoin), "Only avaliable for the locked coin contract");
        uint256 amount = lockedCoin.burnByHash(to, hash);
        require(lockedSupply >= amount, "Balances are not in sync");
        require(_lockedBalances[to] >= amount, "Balances are not in sync");
        _send(address(this), to, amount, "", "", false);
        lockedSupply -= amount; 
        _lockedBalances[to] -= amount;
        require(_lockedBalances[to] == lockedCoin.balanceOf(to), "Balances did not sync");
    }
}