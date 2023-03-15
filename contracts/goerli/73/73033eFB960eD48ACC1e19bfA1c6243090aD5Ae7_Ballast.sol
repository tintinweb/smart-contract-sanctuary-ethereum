/**
 *Submitted for verification at Etherscan.io on 2023-03-15
*/

/**
 *Submitted for verification at Etherscan.io on 2020-07-13
*/

pragma solidity 0.5.14;

contract Ballast {
    address public ownerWallet;
    
    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint totalEarning;
        address[] referral;
    }

    struct PoolUserStruct {
        bool isExist;
        uint id;
       uint payment_received; 
    }
      
    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    
    mapping(address => mapping(uint => uint[])) public userPoolSeqID;
    
    mapping (address => mapping(uint => PoolUserStruct)) public pool1users;
    mapping (uint => address) public pool1userList;
     
    mapping (address => mapping(uint =>PoolUserStruct)) public pool2users;
    mapping (uint => address) public pool2userList;
     
    mapping (address => mapping(uint =>PoolUserStruct)) public pool3users;
    mapping (uint => address) public pool3userList;
     
    mapping(uint => uint) public Auto_Pool_Upline;
    mapping(uint => uint) public Auto_Pool_System;
    
    Ballast public oldBallast;
    
    uint public oldBallastId = 1;
    uint public currUserID = 0;
    
    uint public pool1currUserID = 0;
    uint public pool2currUserID = 0;
    uint public pool3currUserID = 0;
      
    uint public pool1activeUserID = 0;
    uint public pool2activeUserID = 0;
    uint public pool3activeUserID = 0;

    uint public REGESTRATION_FESS=0.08 ether;
    uint public ADMIN_FEES = 0.02 ether;
   
    uint public pool1_price = 0.25 ether;
    uint public pool2_price = 0.50 ether;
    uint public pool3_price = 1 ether;
    
    bool public lockStatus;

    event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
    event regPoolEntry(address indexed _user,uint indexed _poolID,uint indexed _activeUser, uint _time);
    event poolReInvest(uint indexed _poolID, address indexed _user, uint _useID, uint _reInvestID);
    event getPoolPayment(address indexed _user,address indexed _receiver, uint _poolID, uint _time);
    event getPoolMoneyForLevelEvent(uint indexed _poolID,address indexed _user, address indexed _referral, uint _level, uint _amount, uint _time);
    event lostPoolMoneyForLevelEvent(uint indexed _poolID, address indexed _user, address indexed _referral, uint _level, uint _amount, uint _time);
    
    constructor() public {
        ownerWallet = msg.sender;
        oldBallast = Ballast(0x54CC471Dc91C7C9C70320700C5AFB94FAaD9B3a7);
        
        Auto_Pool_Upline[1] = 0.02 ether;
        Auto_Pool_Upline[2] = 0.04 ether;
        Auto_Pool_Upline[3] = 0.08 ether;
        
        Auto_Pool_System[1] = 0.05 ether;
        Auto_Pool_System[2] = 0.10 ether;
        Auto_Pool_System[3] = 0.20 ether;

        
        PoolUserStruct memory pooluserStruct;
        
        pool1currUserID++;

        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool1currUserID,
            payment_received:0
        });
        pool1activeUserID = pool1currUserID;
        pool1users[msg.sender][pool1currUserID] = pooluserStruct;
        pool1userList[pool1currUserID] = msg.sender;
        userPoolSeqID[msg.sender][1].push(pool1currUserID);
        
        pool2currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool2currUserID,
            payment_received:0
        });
        pool2activeUserID = pool2currUserID;
        pool2users[msg.sender][pool2currUserID] = pooluserStruct;
        pool2userList[pool2currUserID] = msg.sender;
        userPoolSeqID[msg.sender][2].push(pool2currUserID);
       
       
        pool3currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool3currUserID,
            payment_received:0
        });
        pool3activeUserID = pool3currUserID;
        pool3users[msg.sender][pool3currUserID] = pooluserStruct;
        pool3userList[pool3currUserID] = msg.sender;
        userPoolSeqID[msg.sender][3].push(pool3currUserID);
    }

    function () external payable {
        revert("No contract call");
    }

    function regUser(uint _referrerID) public payable {
        require(lockStatus == false, "Contract Locked");
        require(!users[msg.sender].isExist, "User exist");
        require(_referrerID > 0 && _referrerID <= currUserID, "Incorrect referrer Id");
        require(msg.value == REGESTRATION_FESS, "Incorrect Value");

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            totalEarning:0,
            referral: new address[](0)
        });

        users[msg.sender] = userStruct;
        userList[currUserID] = msg.sender;
        users[userList[_referrerID]].referral.push(msg.sender);

        uint referrerAmount = REGESTRATION_FESS-ADMIN_FEES;
        
        require(
            (address(uint160(userList[_referrerID])).send(referrerAmount)) && (address(uint160(ownerWallet)).send(ADMIN_FEES)),
            "failed to transfer referrer and ownerWallet fees"
        );
        
        users[userList[_referrerID]].totalEarning += referrerAmount;
        users[ownerWallet].totalEarning += ADMIN_FEES;  

        emit regLevelEvent(msg.sender, userList[_referrerID], now);
    }

    function buyPool1() public payable {
       require(lockStatus == false, "Contract Locked");
       require(users[msg.sender].isExist, "User Not Registered");
       require(msg.value == pool1_price, "Incorrect Value");
        
        pool1currUserID++;
        
        PoolUserStruct memory userStruct;
        
        if(pool1currUserID == 3)
           pool1activeUserID++;
           
        address pool1Currentuser = pool1userList[pool1activeUserID];
        
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool1currUserID,
            payment_received:0
        });
        
        pool1users[msg.sender][pool1currUserID] = userStruct;
        pool1userList[pool1currUserID]=msg.sender;
        userPoolSeqID[msg.sender][1].push(pool1currUserID);
        
        uint payment = pool1users[pool1Currentuser][pool1activeUserID].payment_received;
        
        if(payment == 1){
            payForLevel(1, 10, pool1Currentuser);
            require(address(uint160(ownerWallet)).send(Auto_Pool_System[1]),"failed to transfer system");
        }
        else if(payment == 0){
            require(address(uint160(pool1Currentuser)).send(pool1_price),"failed to transfer direct income");
            emit getPoolPayment(msg.sender,pool1Currentuser, 1, now);
        }
        pool1users[pool1Currentuser][pool1activeUserID].payment_received+=1;
        
        if(pool1users[pool1Currentuser][pool1activeUserID].payment_received>=3)
        { 
            uint pool1PreActiveUserID = pool1activeUserID;
            pool1activeUserID++;
            pool1currUserID++;
            
            address pool1ActiveCurrentuser = pool1userList[pool1activeUserID];
            require(address(uint160(pool1ActiveCurrentuser)).send(pool1_price),"failed to transfer direct income");
            emit getPoolPayment(msg.sender,pool1ActiveCurrentuser, 1, now);
            
            pool1users[pool1ActiveCurrentuser][pool1activeUserID].payment_received+=1;
            
            userStruct = PoolUserStruct({
                isExist:true,
                id:pool1currUserID,
                payment_received:0
            });
       
            pool1users[pool1Currentuser][pool1currUserID] = userStruct;
            pool1userList[pool1currUserID]=pool1Currentuser;
            userPoolSeqID[pool1Currentuser][1].push(pool1currUserID);
            
            emit regPoolEntry(msg.sender, 1, pool1PreActiveUserID, now);
            emit regPoolEntry(pool1Currentuser, 1, pool1PreActiveUserID, now);
            emit poolReInvest(1, pool1Currentuser, pool1PreActiveUserID, pool1currUserID);
        }
        else{
            emit regPoolEntry(msg.sender, 1, pool1activeUserID, now);
        }
    }
    
    function buyPool2() public payable {
       require(lockStatus == false, "Contract Locked");        
       require(users[msg.sender].isExist, "User Not Registered");
       require(msg.value == pool2_price, "Incorrect Value");
        
        pool2currUserID++;
       
        PoolUserStruct memory userStruct;
        
        if(pool2currUserID == 3)
           pool2activeUserID++;
           
        address pool2Currentuser = pool2userList[pool2activeUserID];
        
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool2currUserID,
            payment_received:0
        });
   
        pool2users[msg.sender][pool2currUserID] = userStruct;
        pool2userList[pool2currUserID]=msg.sender;
        userPoolSeqID[msg.sender][2].push(pool2currUserID);
        
        uint payment = pool2users[pool2Currentuser][pool2activeUserID].payment_received;
        
        if(payment == 1){
            payForLevel(2, 10, pool2Currentuser);
            require(address(uint160(ownerWallet)).send(Auto_Pool_System[2]),"failed to transfer system");
        }
        else if(payment == 0){
            require(address(uint160(pool2Currentuser)).send(pool2_price),"failed to transfer direct income");
            emit getPoolPayment(msg.sender,pool2Currentuser, 2, now);
        }
        pool2users[pool2Currentuser][pool2activeUserID].payment_received+=1;
        
        if(pool2users[pool2Currentuser][pool2activeUserID].payment_received>=3)
        { 
            uint pool2PreActiveUserID = pool2activeUserID;
            pool2activeUserID++;
            pool2currUserID++;
            
            address pool2ActiveCurrentuser = pool2userList[pool2activeUserID];
            require(address(uint160(pool2ActiveCurrentuser)).send(pool2_price),"failed to transfer direct income");
            emit getPoolPayment(msg.sender,pool2ActiveCurrentuser, 2, now);
            
            pool2users[pool2ActiveCurrentuser][pool2activeUserID].payment_received+=1;
            
            userStruct = PoolUserStruct({
                isExist:true,
                id:pool2currUserID,
                payment_received:0
            });
       
            pool2users[pool2Currentuser][pool2currUserID] = userStruct;
            pool2userList[pool2currUserID]=pool2Currentuser;
            userPoolSeqID[pool2Currentuser][2].push(pool2currUserID);
            
            emit regPoolEntry(msg.sender, 2, pool2PreActiveUserID, now);
            emit regPoolEntry(pool2Currentuser, 2, pool2PreActiveUserID, now);
            emit poolReInvest(2, pool2Currentuser, pool2PreActiveUserID, pool2currUserID);
        }
        else{
            emit regPoolEntry(msg.sender, 2, pool2activeUserID, now);
        }
    }
    
    function buyPool3() public payable {
       require(lockStatus == false, "Contract Locked");        
       require(users[msg.sender].isExist, "User Not Registered");
       require(msg.value == pool3_price, "Incorrect Value");
        
        pool3currUserID++;
       
        PoolUserStruct memory userStruct;
        
        if(pool3currUserID == 3)
           pool3activeUserID++;
           
        address pool3Currentuser = pool3userList[pool3activeUserID];
        
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool3currUserID,
            payment_received:0
        });
   
        pool3users[msg.sender][pool3currUserID] = userStruct;
        pool3userList[pool3currUserID]=msg.sender;
        userPoolSeqID[msg.sender][3].push(pool3currUserID);
        
        uint payment = pool3users[pool3Currentuser][pool3activeUserID].payment_received;
        
        if(payment == 1){
            payForLevel(3, 10, pool3Currentuser);
            require(address(uint160(ownerWallet)).send(Auto_Pool_System[3]),"failed to transfer system");
        }
        else if(payment == 0){
            require(address(uint160(pool3Currentuser)).send(pool3_price),"failed to transfer direct income");
            emit getPoolPayment(msg.sender,pool3Currentuser, 3, now);
        }
        pool3users[pool3Currentuser][pool3activeUserID].payment_received+=1;
        
        if(pool3users[pool3Currentuser][pool3activeUserID].payment_received>=3)
        { 
            uint pool3PreActiveUserID = pool3activeUserID;
            pool3activeUserID++;
            pool3currUserID++;
            
            address pool3ActiveCurrentuser = pool3userList[pool3activeUserID];
            require(address(uint160(pool3ActiveCurrentuser)).send(pool3_price),"failed to transfer direct income");
            emit getPoolPayment(msg.sender,pool3ActiveCurrentuser, 3, now);
            
            pool3users[pool3ActiveCurrentuser][pool3activeUserID].payment_received+=1;
            
            userStruct = PoolUserStruct({
                isExist:true,
                id:pool3currUserID,
                payment_received:0
            });
       
            pool3users[pool3Currentuser][pool3currUserID] = userStruct;
            pool3userList[pool3currUserID]=pool3Currentuser;
            userPoolSeqID[pool3Currentuser][3].push(pool3currUserID);
            
            emit regPoolEntry(msg.sender, 3, pool3PreActiveUserID, now);
            emit regPoolEntry(pool3Currentuser, 3, pool3PreActiveUserID, now);
            emit poolReInvest(3, pool3Currentuser, pool3PreActiveUserID, pool3currUserID);
        }
        else{
            emit regPoolEntry(msg.sender, 3, pool3activeUserID, now);
        }
    }
    
    function failSafe(address payable _toUser, uint _amount) public returns (bool) {
        require(msg.sender == ownerWallet, "only Owner Wallet");
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");

        (_toUser).transfer(_amount);
        return true;
    }

    function contractLock(bool _lockStatus) public returns (bool) {
        require(msg.sender == ownerWallet, "Invalid User");

        lockStatus = _lockStatus;
        return true;
    } 
    
    function payForLevel(uint _poolID, uint _level, address _user) internal {
        address referer;

        referer = userList[users[_user].referrerID];
        

        if(!users[referer].isExist) referer = userList[1];
        
        if(referer == userList[1]){
            uint uplineAmount = Auto_Pool_Upline[_poolID]*_level;
            require(
                address(uint160(referer)).send(uplineAmount),
                "Upline referer transfer failed"
            );
            users[referer].totalEarning += uplineAmount;
            emit getPoolMoneyForLevelEvent(_poolID, referer, msg.sender, _level, uplineAmount, now);
        }
        else{
            if(userPoolSeqID[referer][_poolID].length > 0){
                if(_level != 0) {
                    require(
                        address(uint160(referer)).send(Auto_Pool_Upline[_poolID]),
                        "Upline referer transfer failed"
                    );
                    _level--;
                    users[referer].totalEarning += Auto_Pool_Upline[_poolID];
                    emit getPoolMoneyForLevelEvent(_poolID, referer, msg.sender, _level, Auto_Pool_Upline[_poolID], now);
                    payForLevel(_poolID, _level, referer);
                }
            }
            else{
                emit lostPoolMoneyForLevelEvent(_poolID, referer, msg.sender, _level, Auto_Pool_Upline[_poolID], now);
                payForLevel(_poolID, _level, referer);
            }
        }
    }
    
    function viewUserReferral(address _user) public view returns(address[] memory) {
        return users[_user].referral;
    }
    
    function viewUserPoolSeqID(address _user,uint _poolID)public view returns(uint[] memory) {
        return userPoolSeqID[_user][_poolID];
    }
    
     /**
     * @dev Update old contract data
     */ 
    function oldBallastSync(uint limit) public {
        require(address(oldBallast) != address(0), "Initialize closed");
        require(msg.sender == ownerWallet, "Access denied");
        
        for (uint i = 0; i <= limit; i++) {
            UserStruct  memory olduser;
            address oldusers = oldBallast.userList(oldBallastId);
            (olduser.isExist, 
            olduser.id, 
            olduser.referrerID, 
            olduser.totalEarning) = oldBallast.users(oldusers);
            address ref = oldBallast.userList(olduser.referrerID);

            if (olduser.isExist) {
                if (!users[oldusers].isExist) {
                    if(oldBallastId == 1)
                        oldusers = ownerWallet;
                        
                    users[oldusers].isExist = true;
                    users[oldusers].id = oldBallastId;
                    users[oldusers].referrerID = olduser.referrerID;
                    users[oldusers].totalEarning = olduser.totalEarning;
                    userList[oldBallastId] = oldusers;
                    if(olduser.referrerID == 1)
                        ref = ownerWallet;
                        
                    users[ref].referral.push(oldusers);
                    
                    emit regLevelEvent(oldusers, ref, now);
                }
                oldBallastId++;
            } else {
                currUserID = oldBallastId-1;
                break;
                
            }
        }
    }
    
    /**
     * @dev Update old contract data
     */ 
    function setoldBallastID(uint _id) public returns(bool) {
        require(ownerWallet == msg.sender, "Access Denied");
        
        oldBallastId = _id;
        return true;
    }

    /**
     * @dev Close old contract interaction
     */ 
    function oldBallastSyncClosed() external {
        require(address(oldBallast) != address(0), "Initialize already closed");
        require(msg.sender == ownerWallet, "Access denied");

        oldBallast = Ballast(0);
    }
}