// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721.sol"; 
import "./DataStructures.sol";
import "./Interfaces.sol";
//import "hardhat/console.sol"; 

// We are the Ethernal. The Ethernal Elves         
// Written by 0xHusky & Beff Jezos. Everything is on-chain for all time to come.
// Version 6.0.0


contract EthernalElvesV6 is ERC721 {

    function name() external pure returns (string memory) { return "Ethernal Elves"; }
    function symbol() external pure returns (string memory) { return "ELV"; }
       
    using DataStructures for DataStructures.ActionVariables;
    using DataStructures for DataStructures.Elf;
    using DataStructures for DataStructures.Token; 

    IElfMetaDataHandler elfmetaDataHandler;
    ICampaigns campaigns;
    IERC20Lite public ren;
    
    using ECDSA for bytes32;
    
//STATE   

    bool public isGameActive;
    bool public isMintOpen;
    bool public isWlOpen;
    bool private initialized;

    address dev1Address;
    address dev2Address;
    address terminus;
    address public validator;
   
    uint256 public INIT_SUPPLY; 
    uint256 public price;
    bytes32 internal ketchup;
    
    uint256[] public _remaining; 
    mapping(uint256 => uint256) public sentinels; //memory slot for Elfs
    mapping(address => uint256) public bankBalances; //memory slot for bank balances
    mapping(address => bool)    public auth;
    mapping(address => uint16)  public whitelist; 


    bool public isTerminalOpen;

    mapping(bytes => uint16)  public usedRenSignatures; 
    mapping(bytes => uint16)  public usedSentinelSignatures; 
/////NEW STORAGE FROM THIS LINE V5///////////////////////////////////////////////////////
    
   
    function setBridge(address _bridge)  public {
       onlyOwner();     
       terminus             = _bridge;       
    }    
    
    function setAuth(address[] calldata adds_, bool status) public {
       onlyOwner();
       
        for (uint256 index = 0; index < adds_.length; index++) {
            auth[adds_[index]] = status;
        }
    }

//EVENTS

    event Action(address indexed from, uint256 indexed action, uint256 indexed tokenId);         
    event BalanceChanged(address indexed owner, uint256 indexed amount, bool indexed subtract);
    //event Campaigns(address indexed owner, uint256 amount, uint256 indexed campaign, uint256 sector, uint256 indexed tokenId);
    event CheckIn(address indexed from, uint256 timestamp, uint256 indexed tokenId, uint256 indexed sentinel);      
    event CheckOut(address indexed to, uint256 timestamp, uint256 indexed tokenId);      
    event RenTransferOut(address indexed from, uint256 timestamp, uint256 indexed renAmount);  
    event RenTransferIn(address indexed from, uint256 timestamp, uint256 indexed renAmount); 
 
   
//GAMEPLAY//

    function unStake(uint256[] calldata ids) external  {
          isPlayer();        

          for (uint256 index = 0; index < ids.length; index++) {  
            _actions(ids[index], 0, msg.sender, 0, 0, false, false, false, 0);
          }
    }

    function sendCampaign(uint256[] calldata ids, uint256 campaign_, uint256 sector_, bool rollWeapons_, bool rollItems_, bool useitem_) external {
          isPlayer();          

          for (uint256 index = 0; index < ids.length; index++) {  
            _actions(ids[index], 2, msg.sender, campaign_, sector_, rollWeapons_, rollItems_, useitem_, 1);
          }
    }

  /*  function passive(uint256[] calldata ids) external {
          isPlayer();         

          for (uint256 index = 0; index < ids.length; index++) {  
            _actions(ids[index], 3, msg.sender, 0, 0, false, false, false, 0);
          }
    }
  */
  
    function returnPassive(uint256[] calldata ids) external  {
          isPlayer();        

          for (uint256 index = 0; index < ids.length; index++) {  
            _actions(ids[index], 4, msg.sender, 0, 0, false, false, false, 0);
          }
    }

 /*   function forging(uint256[] calldata ids) external payable {
          isPlayer();         
        
          for (uint256 index = 0; index < ids.length; index++) {  
            _actions(ids[index], 5, msg.sender, 0, 0, false, false, false, 0);
          }
    }

    function merchant(uint256[] calldata ids) external payable {
          isPlayer();   

          for (uint256 index = 0; index < ids.length; index++) {  
            _actions(ids[index], 6, msg.sender, 0, 0, false, false, false, 0);
          }

    }
*/
    function heal(uint256 healer, uint256 target) external {
        isPlayer();
        _actions(healer, 7, msg.sender, target, 0, false, false, false, 0);
    }    


    function withdrawTokenBalance() external {
      
        require(bankBalances[msg.sender] > 0, "NoBalance");
        ren.mint(msg.sender, bankBalances[msg.sender]); 
        bankBalances[msg.sender] = 0;

    }


 /*   function withdrawSomeTokenBalance(uint256 amount) external {
      
        require(bankBalances[msg.sender] > 0, "NoBalance");
        require(bankBalances[msg.sender] - amount >= 0,"Overdraft Not permitted");
        bankBalances[msg.sender] =  bankBalances[msg.sender] - amount; //update ledger first
        ren.mint(msg.sender, amount); 
      

    }

*/

//INTERNALS
    
        
        function _actions(
            uint256 id_, 
            uint action, 
            address elfOwner, 
            uint256 campaign_, 
            uint256 sector_, 
            bool rollWeapons, 
            bool rollItems, 
            bool useItem, 
            uint256 gameMode_) 
        
        private {

            DataStructures.Elf memory elf = DataStructures.getElf(sentinels[id_]);
            DataStructures.ActionVariables memory actions;
            require(isGameActive);
            require(ownerOf[id_] == msg.sender || elf.owner == msg.sender, "NotYourElf");
            require(elf.action != 8, "elf in Polygon");

            uint256 rand = _rand();
                
                if(action == 0){//Unstake if currently staked

                    require(ownerOf[id_] == address(this));
                    require(elf.timestamp < block.timestamp, "elf busy");
                     
                     if(elf.action == 3){
                     actions.timeDiff = (block.timestamp - elf.timestamp) / 1 days; //amount of time spent in camp CHANGE TO 1 DAYS!
                     elf.level = _exitPassive(actions.timeDiff, elf.level);
                    
                     }

                    _transfer(address(this), elfOwner, id_);      

                    elf.owner = address(0);                            

                }else if(action == 2){//campaign loop - bloodthirst and rampage mode loop.

                    require(elf.timestamp < block.timestamp, "elf busy");
                    require(elf.action != 3, "exit passive mode first");                 
            
                        if(ownerOf[id_] != address(this)){
                        _transfer(elfOwner, address(this), id_);
                        elf.owner = elfOwner;
                        }
 
                    (elf.level, actions.reward, elf.timestamp, elf.inventory) = campaigns.gameEngine(campaign_, sector_, elf.level, elf.attackPoints, elf.healthPoints, elf.inventory, useItem);
                    
                    uint256 options;
                    if(rollWeapons && rollItems){
                        options = 3;
                        }else if(rollWeapons){
                        options = 1;
                        }else if(rollItems){
                        options = 2;
                        }else{
                        options = 0;
                    }
                  
                    if(options > 0){
                       (elf.weaponTier, elf.primaryWeapon, elf.inventory) 

                                    = DataStructures.roll(id_, elf.level, _rand(), options, elf.weaponTier, elf.primaryWeapon, elf.inventory);                                    
                                    
                    }
                    
                    if(gameMode_ == 1 || gameMode_ == 2)  ren.mint(msg.sender, actions.reward);   
                    if(gameMode_ == 3) elf.level = elf.level + 1;
                    
                    //emit Campaigns(msg.sender, actions.reward, campaign_, sector_, id_);

                
                }else if(action == 3){//passive campaign

                    require(elf.timestamp < block.timestamp, "elf busy");
                    
                        if(ownerOf[id_] != address(this)){
                            _transfer(elfOwner, address(this), id_);
                            elf.owner = elfOwner;
                         
                        }

                    elf.timestamp = block.timestamp; //set timestamp to current block time

                }else if(action == 4){///return from passive mode
                    
                    require(elf.action == 3);                    

                    actions.timeDiff = (block.timestamp - elf.timestamp) / 1 days; //amount of time spent in camp CHANGE TO 1 DAYS!

                    elf.level = _exitPassive(actions.timeDiff, elf.level);
                   
    
                }else if(action == 5){//forge loop for weapons
                   
                    require(msg.value >= .04 ether, "Wrong value sent");  
                    require(elf.action != 3, "Cant roll in passive"); //Cant roll in passve mode  
                    require(elf.weaponTier <= 3, "Cannot roll a new weapon"); //T4 and T5 cannot roll new weapons
                   //                    
                   // (elf.weaponTier, elf.primaryWeapon, elf.inventory) = DataStructures.roll(id_, elf.level, rand, 1, elf.weaponTier, elf.primaryWeapon, elf.inventory);
                   (elf.primaryWeapon, elf.weaponTier) = _rollWeapon(elf.level, id_, rand);
   
                
                }else if(action == 6){//item or merchant loop
                   
                    require(msg.value >= .01 ether); 
                    require(elf.action != 3); //Cant roll in passve mode
                    (elf.weaponTier, elf.primaryWeapon, elf.inventory) = DataStructures.roll(id_, elf.level, rand, 2, elf.weaponTier, elf.primaryWeapon, elf.inventory);                      

                }else if(action == 7){//healing loop


                    require(elf.sentinelClass == 0, "not a healer"); 
                    require(elf.action != 3, "cant heal while passive"); //Cant heal in passve mode
                    require(elf.timestamp < block.timestamp, "elf busy");

                        if(ownerOf[id_] != address(this)){
                        _transfer(elfOwner, address(this), id_);
                        elf.owner = elfOwner;
                        }
                    
                    
                    elf.timestamp = block.timestamp + (12 hours);

                    elf.level = elf.level + 1;
                    
                    {   

                        DataStructures.Elf memory hElf = DataStructures.getElf(sentinels[campaign_]);//using the campaign varialbe for elfId here.
                        require(ownerOf[campaign_] == msg.sender || hElf.owner == msg.sender, "NotYourElf");
                               
                                if(block.timestamp < hElf.timestamp){

                                        actions.timeDiff = hElf.timestamp - block.timestamp;
                
                                        actions.timeDiff = actions.timeDiff > 0 ? 
                                            
                                            hElf.sentinelClass == 0 ? 0 : 
                                            hElf.sentinelClass == 1 ? actions.timeDiff * 1/4 : 
                                            actions.timeDiff * 1/2
                                        
                                        : actions.timeDiff;
                                        
                                        hElf.timestamp = hElf.timestamp - actions.timeDiff;                        
                                        
                                }
                            
                        actions.traits = DataStructures.packAttributes(hElf.hair, hElf.race, hElf.accessories);
                        actions.class =  DataStructures.packAttributes(hElf.sentinelClass, hElf.weaponTier, hElf.inventory);
                                
                        sentinels[campaign_] = DataStructures._setElf(hElf.owner, hElf.timestamp, hElf.action, hElf.healthPoints, hElf.attackPoints, hElf.primaryWeapon, hElf.level, actions.traits, actions.class);

                }
                }else if (action == 8){//checkIn loop Do not remove
                    
                        if(ownerOf[id_] != address(this)){
                             _transfer(elfOwner, address(this), id_);
                             elf.owner = elfOwner;                                
                        }
                    

                 
                }           
             
            actions.traits   = DataStructures.packAttributes(elf.hair, elf.race, elf.accessories);
            actions.class    = DataStructures.packAttributes(elf.sentinelClass, elf.weaponTier, elf.inventory);
            elf.healthPoints = DataStructures.calcHealthPoints(elf.sentinelClass, elf.level); 
            elf.attackPoints = DataStructures.calcAttackPoints(elf.sentinelClass, elf.weaponTier);  
            elf.level        = elf.level > 100 ? 100 : elf.level; 
            elf.action       = action;

            sentinels[id_] = DataStructures._setElf(elf.owner, elf.timestamp, elf.action, elf.healthPoints, elf.attackPoints, elf.primaryWeapon, elf.level, actions.traits, actions.class);
            emit Action(msg.sender, action, id_); 
    }



    function _exitPassive(uint256 timeDiff, uint256 _level) private returns (uint256 level) {
            
            uint256 rewards;

                    if(timeDiff >= 7){
                        rewards = 140 ether;
                    }
                    if(timeDiff >= 14 && timeDiff < 30){
                        rewards = 420 ether;
                    }
                    if(timeDiff >= 30){
                        rewards = 1200 ether;
                    }
                    
                    level = _level + (timeDiff * 1); //one level per day
                    
                    if(level >= 100){
                        level = 100;
                    }                    
                   
                    ren.mint(msg.sender, rewards);                     

    }


    function _rollWeapon(uint256 level, uint256 id, uint256 rand) internal pure returns (uint256 newWeapon, uint256 newWeaponTier) {
    
                
        uint256 levelTier = level == 100 ? 5 : uint256((level/20) + 1);
        uint256  chance = _randomize(rand, "Weapon", id) % 100;
      
                if(chance > 10 && chance < 80){
        
                             newWeaponTier = levelTier;
        
                        }else if (chance > 80 ){
        
                             newWeaponTier = levelTier + 1 > 4 ? 4 : levelTier + 1;
        
                        }else{

                                newWeaponTier = levelTier - 1 < 1 ? 1 : levelTier - 1;          
                        }
                         
                newWeaponTier = newWeaponTier > 3 ? 3 : newWeaponTier;

                newWeapon = ((newWeaponTier - 1) * 3) + (rand % 3);              
        
    }
    

    function _setAccountBalance(address _owner, uint256 _amount, bool _subtract) private {
            
            _subtract ? bankBalances[_owner] -= _amount : bankBalances[_owner] += _amount;
            emit BalanceChanged(_owner, _amount, _subtract);
    }


    function _randomize(uint256 ran, string memory dom, uint256 ness) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(ran,dom,ness)));}

    function _rand() internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp, block.basefee, ketchup)));}

//PUBLIC VIEWS
    function tokenURI(uint256 _id) external view returns(string memory) {
    return elfmetaDataHandler.getTokenURI(uint16(_id), sentinels[_id]);
    }

    function attributes(uint256 _id) external view returns(uint hair, uint race, uint accessories, uint sentinelClass, uint weaponTier, uint inventory){
    uint256 character = sentinels[_id];

    uint _traits =        uint256(uint8(character>>240));
    uint _class =         uint256(uint8(character>>248));

    hair           = (_traits / 100) % 10;
    race           = (_traits / 10) % 10;
    accessories    = (_traits) % 10;
    sentinelClass  = (_class / 100) % 10;
    weaponTier     = (_class / 10) % 10;
    inventory      = (_class) % 10; 

}

function getSentinel(uint256 _id) external view returns(uint256 sentinel){
    return sentinel = sentinels[_id];
}


function getToken(uint256 _id) external view returns(DataStructures.Token memory token){
   
    return DataStructures.getToken(sentinels[_id]);
}

function elves(uint256 _id) external view returns(address owner, uint timestamp, uint action, uint healthPoints, uint attackPoints, uint primaryWeapon, uint level) {

    uint256 character = sentinels[_id];

    owner =          address(uint160(uint256(character)));
    timestamp =      uint(uint40(character>>160));
    action =         uint(uint8(character>>200));
    healthPoints =   uint(uint8(character>>208));
    attackPoints =   uint(uint8(character>>216));
    primaryWeapon =  uint(uint8(character>>224));
    level =          uint(uint8(character>>232));   

}

//Modifiers but as functions. Less Gas
    function isPlayer() internal {    
        uint256 size = 0;
        address acc = msg.sender;
        assembly { size := extcodesize(acc)}
        require((msg.sender == tx.origin && size == 0));
        ketchup = keccak256(abi.encodePacked(acc, block.coinbase));
    }


    function onlyOwner() internal view {    
        require(admin == msg.sender || auth[msg.sender] == true || dev1Address == msg.sender || dev2Address == msg.sender);
    }

    function checkBalance(uint256 balance, uint256 amount) internal view {    
        require(balance - amount >= 0, "notEnoughBalance");           
    }


//ADMIN Only
    function withdrawAll() public {
        onlyOwner();
        uint256 balance = address(this).balance;
        
        uint256 devShare = balance/2;      

        require(balance > 0);
        _withdraw(dev1Address, devShare);
        _withdraw(dev2Address, devShare);
    }

    //Internal withdraw
    function _withdraw(address _address, uint256 _amount) private {

        (bool success, ) = _address.call{value: _amount}("");
        require(success);
    }

    function flipActiveStatus() external {
        onlyOwner();
        isGameActive = !isGameActive;
    }

    function flipMint() external {
        onlyOwner();
        isMintOpen = !isMintOpen;
    }


     function flipTerminal() external {
        onlyOwner();
        isTerminalOpen = !isTerminalOpen;
    }

    
    
   function adminSetAccountBalance(address _owner, uint256 _amount) public {                
        onlyOwner();
        bankBalances[_owner] += _amount;
    }
 

    function setElfManually(uint id, uint8 _primaryWeapon, uint8 _weaponTier, uint8 _attackPoints, uint8 _healthPoints, uint8 _level, uint8 _inventory, uint8 _race, uint8 _class, uint8 _accessories) external {
        onlyOwner();
        DataStructures.Elf memory elf = DataStructures.getElf(sentinels[id]);
        DataStructures.ActionVariables memory actions;

        elf.owner           = elf.owner;
        elf.timestamp       = elf.timestamp;
        elf.action          = elf.action;
        elf.healthPoints    = _healthPoints;
        elf.attackPoints    = _attackPoints;
        elf.primaryWeapon   = _primaryWeapon;
        elf.level           = _level;
        elf.weaponTier      = _weaponTier;
        elf.inventory       = _inventory;
        elf.race            = _race;
        elf.sentinelClass   = _class;
        elf.accessories     = _accessories;

        actions.traits = DataStructures.packAttributes(elf.hair, elf.race, elf.accessories);
        actions.class =  DataStructures.packAttributes(elf.sentinelClass, elf.weaponTier, elf.inventory);
                       
        sentinels[id] = DataStructures._setElf(elf.owner, elf.timestamp, elf.action, elf.healthPoints, elf.attackPoints, elf.primaryWeapon, elf.level, actions.traits, actions.class);
        
    }

    //Bridge    

    function prismBridge(uint256[] calldata ids, uint256[] calldata sentinel, address owner) external {
        require (msg.sender == terminus || admin == msg.sender, "notBridge");
        //return to eth
        uint256 action = 0;
        
        for(uint i = 0; i < ids.length; i++){
            
           //Get currently staked elf
            DataStructures.Elf memory elfStaked = DataStructures.getElf(sentinels[ids[i]]);
           //Get new sentinel ID sent from Polygon 
            DataStructures.Elf memory elf = DataStructures.getElf(sentinel[i]);
            DataStructures.ActionVariables memory actions;
            //check if owners are the same. Check is owner is sender.
            require(elf.owner == elfStaked.owner && elf.owner == owner, "NotYourElf");
            require(ownerOf[ids[i]] == address(this));
            
            _transfer(address(this), owner, ids[i]);      
            elf.owner = address(0);    
           
            actions.traits = DataStructures.packAttributes(elf.hair, elf.race, elf.accessories);
            actions.class =  DataStructures.packAttributes(elf.sentinelClass, elf.weaponTier, elf.inventory);

            sentinels[ids[i]] = DataStructures._setElf(elf.owner, elf.timestamp, action, elf.healthPoints, elf.attackPoints, elf.primaryWeapon, elf.level, actions.traits, actions.class);
            emit Action(owner, action, ids[i]); 
            emit CheckOut(owner, block.timestamp, ids[i]);
        
        }        

    } 

    function exitElf(uint256[] calldata ids, address owner) external {
        require (msg.sender == terminus || admin == msg.sender, "notBridge");
     
        uint256 action = 8;
        //send through the portal to polygon
        

        for(uint i = 0; i < ids.length; i++){            
           
            DataStructures.Elf memory elf = DataStructures.getElf(sentinels[ids[i]]);
            DataStructures.ActionVariables memory actions;
            
            require (elf.action !=8, "ElfAlreadyExited");
            
             if(ownerOf[ids[i]] != address(this)){
                _transfer(owner, address(this), ids[i]);
                elf.owner = owner;                                
             }

            actions.traits = DataStructures.packAttributes(elf.hair, elf.race, elf.accessories);
            actions.class =  DataStructures.packAttributes(elf.sentinelClass, elf.weaponTier, elf.inventory);

            sentinels[ids[i]] = DataStructures._setElf(elf.owner, elf.timestamp, action, elf.healthPoints, elf.attackPoints, elf.primaryWeapon, elf.level, actions.traits, actions.class);
            emit Action(owner, action, ids[i]); 
            emit CheckIn(owner, block.timestamp, ids[i], sentinels[ids[i]]);          

        }
        //emit event    ids   sentinelTransfers
        
    }

    function setAccountBalance(address _owner, uint256 _amount, bool _subtract, uint256 _index) external {
            
            require (msg.sender == terminus || admin == msg.sender, "notBridge");

                if(_index == 0){
                        
                        if(_subtract){

                            ren.burn(_owner, _amount);
                            emit RenTransferOut(_owner,block.timestamp,_amount);

                        }else{

                            ren.mint(_owner, _amount); 
                            emit RenTransferIn(_owner,block.timestamp,_amount);          

                        }                                   

                }              

     
            //emit event to let the dapp know you have exited.            
            
    } 


  

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

/// @notice Modern and gas efficient ERC-721 + ERC-20/EIP-2612-like implementation,
/// including the MetaData, and partially, Enumerable extensions.
contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    address implementation_;
    address public admin;

    /*///////////////////////////////////////////////////////////////
                             ERC-721 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;
    uint256 public maxSupply;

    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                             VIEW FUNCTION
    //////////////////////////////////////////////////////////////*/

    function owner() external view returns (address) {
        return admin;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC-20-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/

    function transfer(address to, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId], "NOT_OWNER");

        _transfer(msg.sender, to, tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                              ERC-721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        returns (bool supported)
    {
        supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }

    function approve(address spender, uint256 tokenId) external {
        address owner_ = ownerOf[tokenId];

        require(
            msg.sender == owner_ || isApprovedForAll[owner_][msg.sender],
            "NOT_APPROVED"
        );

        getApproved[tokenId] = spender;

        emit Approval(owner_, spender, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        address owner_ = ownerOf[tokenId];

        require(
            msg.sender == owner_ ||
                msg.sender == getApproved[tokenId] ||
                isApprovedForAll[owner_][msg.sender],
            "NOT_APPROVED"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId);

        if (to.code.length != 0) {
            // selector = `onERC721Received(address,address,uint,bytes)`
            (, bytes memory returned) = to.staticcall(
                abi.encodeWithSelector(
                    0x150b7a02,
                    msg.sender,
                    from, 
                    tokenId,
                    data
                )
            );

            bytes4 selector = abi.decode(returned, (bytes4));

            require(selector == 0x150b7a02, "NOT_ERC721_RECEIVER");
        }
    }

    /*///////////////////////////////////////////////////////////////
                          INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/

    function _transfer(address from, address to, uint256 tokenId) internal {
        
        require(ownerOf[tokenId] == from);

        balanceOf[from]--;
        balanceOf[to]++;

        delete getApproved[tokenId];

        ownerOf[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal {
        require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");
        require(totalSupply++ <= maxSupply, "MAX SUPPLY REACHED");

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address owner_ = ownerOf[tokenId];

        require(ownerOf[tokenId] != address(0), "NOT_MINTED");

        totalSupply--;
        balanceOf[owner_]--;

        delete ownerOf[tokenId];

        emit Transfer(owner_, address(0), tokenId);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;
//import "hardhat/console.sol"; ///REMOVE BEFORE DEPLOYMENT
//v 1.0.3

library DataStructures {

/////////////DATA STRUCTURES///////////////////////////////
    struct Elf {
            address owner;  
            uint256 timestamp; 
            uint256 action; 
            uint256 healthPoints;
            uint256 attackPoints; 
            uint256 primaryWeapon; 
            uint256 level;
            uint256 hair;
            uint256 race; 
            uint256 accessories; 
            uint256 sentinelClass; 
            uint256 weaponTier; 
            uint256 inventory; 
    }

    struct Token {
            address owner;  
            uint256 timestamp; 
            uint8 action; 
            uint8 healthPoints;
            uint8 attackPoints; 
            uint8 primaryWeapon; 
            uint8 level;
            uint8 hair;
            uint8 race; 
            uint8 accessories; 
            uint8 sentinelClass; 
            uint8 weaponTier; 
            uint8 inventory; 
    }

    struct ActionVariables {

            uint256 reward;
            uint256 timeDiff;
            uint256 traits; 
            uint256 class;  
    }

    struct Camps {
            uint32 baseRewards; 
            uint32 creatureCount; 
            uint32 creatureHealth; 
            uint32 expPoints; 
            uint32 minLevel;
            uint32 itemDrop;
            uint32 weaponDrop;
            uint32 spare;
    }

    /*Dont Delete, just keep it for reference

    struct Attributes { 
            uint256 hair; //MAX 3 3 hair traits
            uint256 race;  //MAX 6 Body 4 for body
            uint256 accessories; //MAX 7 4 
            uint256 sentinelClass; //MAX 3 3 in class
            uint256 weaponTier; //MAX 6 5 tiers
            uint256 inventory; //MAX 7 6 items
    }

    */

/////////////////////////////////////////////////////
function getElf(uint256 character) internal pure returns(Elf memory _elf) {
   
    _elf.owner =          address(uint160(uint256(character)));
    _elf.timestamp =      uint256(uint40(character>>160));
    _elf.action =         uint256(uint8(character>>200));
    _elf.healthPoints =       uint256(uint8(character>>208));
    _elf.attackPoints =   uint256(uint8(character>>216));
    _elf.primaryWeapon =  uint256(uint8(character>>224));
    _elf.level    =       uint256(uint8(character>>232));
    _elf.hair           = (uint256(uint8(character>>240)) / 100) % 10;
    _elf.race           = (uint256(uint8(character>>240)) / 10) % 10;
    _elf.accessories    = (uint256(uint8(character>>240))) % 10;
    _elf.sentinelClass  = (uint256(uint8(character>>248)) / 100) % 10;
    _elf.weaponTier     = (uint256(uint8(character>>248)) / 10) % 10;
    _elf.inventory      = (uint256(uint8(character>>248))) % 10; 

} 

function getToken(uint256 character) internal pure returns(Token memory token) {
   
    token.owner          = address(uint160(uint256(character)));
    token.timestamp      = uint256(uint40(character>>160));
    token.action         = (uint8(character>>200));
    token.healthPoints   = (uint8(character>>208));
    token.attackPoints   = (uint8(character>>216));
    token.primaryWeapon  = (uint8(character>>224));
    token.level          = (uint8(character>>232));
    token.hair           = ((uint8(character>>240)) / 100) % 10; //MAX 3
    token.race           = ((uint8(character>>240)) / 10) % 10; //Max6
    token.accessories    = ((uint8(character>>240))) % 10; //Max7
    token.sentinelClass  = ((uint8(character>>248)) / 100) % 10; //MAX 3
    token.weaponTier     = ((uint8(character>>248)) / 10) % 10; //MAX 6
    token.inventory      = ((uint8(character>>248))) % 10; //MAX 7

    token.hair = (token.sentinelClass * 3) + (token.hair + 1);
    token.race = (token.sentinelClass * 4) + (token.race + 1);
    token.primaryWeapon = token.primaryWeapon == 69 ? 69 : (token.sentinelClass * 15) + (token.primaryWeapon + 1);
    token.accessories = (token.sentinelClass * 7) + (token.accessories + 1);

}

function _setElf(
                address owner, uint256 timestamp, uint256 action, uint256 healthPoints, 
                uint256 attackPoints, uint256 primaryWeapon, 
                uint256 level, uint256 traits, uint256 class )

    internal pure returns (uint256 sentinel) {

    uint256 character = uint256(uint160(address(owner)));
    
    character |= timestamp<<160;
    character |= action<<200;
    character |= healthPoints<<208;
    character |= attackPoints<<216;
    character |= primaryWeapon<<224;
    character |= level<<232;
    character |= traits<<240;
    character |= class<<248;
    
    return character;
}

//////////////////////////////HELPERS/////////////////

function packAttributes(uint hundreds, uint tens, uint ones) internal pure returns (uint256 packedAttributes) {
    packedAttributes = uint256(hundreds*100 + tens*10 + ones);
    return packedAttributes;
}

function calcAttackPoints(uint256 sentinelClass, uint256 weaponTier) internal pure returns (uint256 attackPoints) {

        attackPoints = ((sentinelClass + 1) * 2) + (weaponTier * 2);
        
        return attackPoints;
}

function calcHealthPoints(uint256 sentinelClass, uint256 level) internal pure returns (uint256 healthPoints) {

        healthPoints = (level/(3) +2) + (20 - (sentinelClass * 4));
        
        return healthPoints;
}

function calcCreatureHealth(uint256 sector, uint256 baseCreatureHealth) internal pure returns (uint256 creatureHealth) {

        creatureHealth = ((sector - 1) * 12) + baseCreatureHealth; 
        
        return creatureHealth;
}

function roll(uint256 id_, uint256 level_, uint256 rand, uint256 rollOption_, uint256 weaponTier_, uint256 primaryWeapon_, uint256 inventory_) 
internal pure 
returns (uint256 newWeaponTier, uint256 newWeapon, uint256 newInventory) {

   uint256 levelTier = level_ == 100 ? 5 : uint256((level_/20) + 1);

   newWeaponTier = weaponTier_;
   newWeapon     = primaryWeapon_;
   newInventory  = inventory_;


   if(rollOption_ == 1 || rollOption_ == 3){
       //Weapons
      
        uint16  chance = uint16(_randomize(rand, "Weapon", id_)) % 100;
       // console.log("chance: ", chance);
                if(chance > 10 && chance < 80){
        
                              newWeaponTier = levelTier;
        
                        }else if (chance > 80 ){
        
                              newWeaponTier = levelTier + 1 > 5 ? 5 : levelTier + 1;
        
                        }else{

                                newWeaponTier = levelTier - 1 < 1 ? 1 : levelTier - 1;          
                        }

                                         
        

        newWeapon = newWeaponTier == 0 ? 0 : ((newWeaponTier - 1) * 3) + (rand % 3);  
        

   }
   
   if(rollOption_ == 2 || rollOption_ == 3){//Items Loop
      
       
        uint16 morerand = uint16(_randomize(rand, "Inventory", id_));
        uint16 diceRoll = uint16(_randomize(rand, "Dice", id_));
        
        diceRoll = (diceRoll % 100);
        
        if(diceRoll <= 20){

            newInventory = levelTier > 3 ? morerand % 3 + 3: morerand % 6 + 1;
            //console.log("Token#: ", id_);
            //console.log("newITEM: ", newInventory);
        } 

   }
                      
              
}


function _randomize(uint256 ran, string memory dom, uint256 ness) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(ran,dom,ness)));}



}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

interface IERC20Lite {
    
    function transfer(address to, uint256 value) external returns (bool);
    function burn(address from, uint256 value) external;
    function mint(address to, uint256 value) external; 
    function approve(address spender, uint256 value) external returns (bool); 
    function balanceOf(address account) external returns (uint256); 
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

interface IElfMetaDataHandler {    
function getTokenURI(uint16 id_, uint256 sentinel) external view returns (string memory);
}

interface ICampaigns {
function gameEngine(uint256 _campId, uint256 _sector, uint256 _level, uint256 _attackPoints, uint256 _healthPoints, uint256 _inventory, bool _useItem) external 
returns(uint256 level, uint256 rewards, uint256 timestamp, uint256 inventory);
}

interface IElves {    
    function prismBridge(uint256[] calldata id, uint256[] calldata sentinel, address owner) external;    
    function exitElf(uint256[] calldata ids, address owner) external;
    function setAccountBalance(address _owner, uint256 _amount, bool _subtract, uint256 _index) external;
}

interface IERC721Lite {
    function transferFrom(address from, address to, uint256 id) external;   
    function transfer(address to, uint256 id) external;
    function ownerOf(uint256 id) external returns (address owner);
    function mint(address to, uint256 tokenid) external;
}

interface IERC1155Lite {
    function burn(address from,uint256 id, uint256 value) external;
    function balanceOf(address _owner, uint256 _id) external returns (uint256); 
}

 
//1155
interface IERC165 {
    function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}

interface IERC1155 is IERC165 {
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
  function setApprovalForAll(address _operator, bool _approved) external;
  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}

interface IERC1155Metadata {
  event URI(string _uri, uint256 indexed _id);
  function uri(uint256 _id) external view returns (string memory);
}

interface IERC1155TokenReceiver {
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);
  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}