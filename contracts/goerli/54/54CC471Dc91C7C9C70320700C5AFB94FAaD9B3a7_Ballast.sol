/**
 *Submitted for verification at Etherscan.io on 2023-03-15
*/

/**
 *Submitted for verification at Etherscan.io on 2020-06-24
*/

pragma solidity 0.5.14;


contract Ballast{

    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint totalEarning;
        address[] referral;
        mapping(uint => uint) levelExpired;
    }
    
    struct AutoPoolStruct{
        bool isExist;
        bool poolStatus;
        uint seqID;
        uint poolReferrerID;
        uint totalEarning;
        address[] poolReferral;
    }
    
    address payable public admin;
    uint public entryFee = 0.08 ether;
    uint public adminFee = 0.02 ether;
    uint public Auto_Pool_Limit = 3;
    
    mapping(address => UserStruct) public users;
    mapping(address => mapping(uint => mapping(uint =>AutoPoolStruct))) public usersPool;
    mapping(uint => uint) public Auto_Pool_SeqID;
    mapping(uint => uint) public Auto_Pool;
    mapping(uint => uint) public Auto_Pool_Upline;
    mapping(uint => uint) public Auto_Pool_System;
    mapping(uint => mapping (uint => address)) public userPoolList;
    mapping(uint => address) public userList;
    mapping(address => mapping (uint => bool)) public userPoolStatus;
    mapping(address => mapping(uint => uint[])) public userPoolSeqID;
    
    uint public currUserID = 0;
    bool public lockStatus;

    event UserEntryEvent(
        address indexed _user,
        address indexed _referrer,
        uint _time
    );
    event AutoPoolEvent(
        uint indexed _referrerID,
        address indexed _user,
        uint indexed _poolID,
        uint _time
    );
    event AutoPoolUplineEvent(
       uint indexed _referrerID,
       uint indexed _poolID,
       address indexed _user,
       address[10] _uplines
    );
    
    constructor() public {
        admin = msg.sender;

        Auto_Pool_SeqID[1] = 0;
        Auto_Pool_SeqID[2] = 0;
        Auto_Pool_SeqID[3] = 0;
        
        Auto_Pool[1] = 0.25 ether;
        Auto_Pool[2] = 0.50 ether;
        Auto_Pool[3] = 1 ether;
        
        Auto_Pool_Upline[1] = 0.02 ether;
        Auto_Pool_Upline[2] = 0.04 ether;
        Auto_Pool_Upline[3] = 0.08 ether;
        
        Auto_Pool_System[1] = 0.05 ether;
        Auto_Pool_System[2] = 0.10 ether;
        Auto_Pool_System[3] = 0.20 ether;
        
        UserStruct memory userStruct;
        currUserID++;
        Auto_Pool_SeqID[1]++;
        Auto_Pool_SeqID[2]++;
        Auto_Pool_SeqID[3]++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: 0,
            totalEarning:0,
            referral: new address[](0)
        });
        users[admin] = userStruct;    
        userList[currUserID] = admin;
        
        AutoPoolStruct memory autoPoolStruct;
        autoPoolStruct = AutoPoolStruct({
            isExist: true,
            poolStatus: true,
            seqID: Auto_Pool_SeqID[1],
            totalEarning:0,
            poolReferrerID: 0,
            poolReferral: new address[](0)
        });
        usersPool[admin][1][1] = autoPoolStruct;
        usersPool[admin][2][1] = autoPoolStruct;
        usersPool[admin][3][1] = autoPoolStruct;
        userPoolList[1][Auto_Pool_SeqID[1]] = admin;
        userPoolList[2][Auto_Pool_SeqID[2]] = admin;
        userPoolList[3][Auto_Pool_SeqID[3]] = admin;
        userPoolSeqID[admin][1].push(Auto_Pool_SeqID[1]);
        userPoolSeqID[admin][2].push(Auto_Pool_SeqID[2]);
        userPoolSeqID[admin][3].push(Auto_Pool_SeqID[3]);
    }
    
    function() external {
        revert("No contract call");
    }
    
    function userEntry(
        uint _referrerID
    ) 
        payable
        public 
    {
        
        require(
            lockStatus == false, 
            "Contract Locked"
        );
        require(
            !users[msg.sender].isExist,
            'User exist'
        );
        require(
            _referrerID > 0 && _referrerID <= currUserID,
            'Incorrect referrer Id'
        );
        require(
            msg.value == entryFee,
            "insufficient value"
        );
        
        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            totalEarning:0,
            referrerID: _referrerID,
            referral: new address[](0)
        });

        users[msg.sender] = userStruct;
        userList[currUserID] = msg.sender;

        users[userList[_referrerID]].referral.push(msg.sender);
        uint referrerAmount = entryFee-adminFee;
        address(uint160(userList[_referrerID])).transfer(referrerAmount); 
        admin.transfer(adminFee);
        users[userList[_referrerID]].totalEarning += referrerAmount;
        users[admin].totalEarning += adminFee;   
        emit UserEntryEvent(
            msg.sender,
            userList[_referrerID],
            now
        );
    }
    
    function AutoPool(
        uint _poolID,
        uint _poolRefSeqID
    ) 
        payable
        public 
    {   
        require(lockStatus == false, "Contract Locked");
        require(users[msg.sender].isExist,'User not exist');
        require(!userPoolStatus[msg.sender][_poolID],'User exist in pool');
        // require(usersPool[userList[_poolRefSeqID]][_poolID].poolStatus,'pool referrer is not exist');
        require(_poolID <= 3 && _poolID > 0,"_poolID must be greather than zero and less than 4");
        require(
            _poolRefSeqID > 0 && _poolRefSeqID <= Auto_Pool_SeqID[_poolID],
            'Incorrect pool referrer Id'
        );
        require(
            usersPool[userPoolList[_poolID][_poolRefSeqID]][_poolID][_poolRefSeqID].poolReferral.length < Auto_Pool_Limit,
            "reached poolReferral limit"
        );
        require(msg.value == Auto_Pool[_poolID],"Incorrect value");
        
        Auto_Pool_SeqID[_poolID]++;
        
        AutoPoolStruct memory autoPoolStruct;
        autoPoolStruct = AutoPoolStruct({
            isExist: true,
            poolStatus: false,
            seqID: Auto_Pool_SeqID[_poolID],
            totalEarning:0,
            poolReferrerID: _poolRefSeqID,
            poolReferral: new address[](0)
        });
        
        usersPool[msg.sender][_poolID][Auto_Pool_SeqID[_poolID]] = autoPoolStruct;
        
        userPoolList[_poolID][Auto_Pool_SeqID[_poolID]] = msg.sender;
        userPoolSeqID[msg.sender][_poolID].push(Auto_Pool_SeqID[_poolID]);
        userPoolStatus[msg.sender][_poolID] = true;
        
        usersPool[userPoolList[_poolID][_poolRefSeqID]][_poolID][_poolRefSeqID].poolReferral.push(msg.sender);
        
        if(usersPool[userPoolList[_poolID][_poolRefSeqID]][_poolID][_poolRefSeqID].poolReferral.length == 1){
            address(uint160(userPoolList[_poolID][_poolRefSeqID])).transfer(Auto_Pool[_poolID]); 
            usersPool[userPoolList[_poolID][_poolRefSeqID]][_poolID][_poolRefSeqID].totalEarning += Auto_Pool[_poolID];
        }
        else if(usersPool[userPoolList[_poolID][_poolRefSeqID]][_poolID][_poolRefSeqID].poolReferral.length == 2){
            autoPoolUplines(msg.sender, _poolID,Auto_Pool_SeqID[_poolID]);
        }
        else{
            address(uint160(userPoolList[_poolID][_poolRefSeqID])).transfer(Auto_Pool[_poolID]);
            usersPool[userPoolList[_poolID][_poolRefSeqID]][_poolID][_poolRefSeqID].totalEarning += Auto_Pool[_poolID];
            
            Auto_Pool_SeqID[_poolID]++;
        
            AutoPoolStruct memory autoPoolStructReinvest;
            autoPoolStructReinvest = AutoPoolStruct({
                isExist: true,
                poolStatus: false,
                seqID: Auto_Pool_SeqID[_poolID],
                totalEarning:0,
                poolReferrerID: usersPool[userPoolList[_poolID][_poolRefSeqID]][_poolID][_poolRefSeqID].poolReferrerID,
                poolReferral: new address[](0)
            });
            
            usersPool[userPoolList[_poolID][_poolRefSeqID]][_poolID][Auto_Pool_SeqID[_poolID]] = autoPoolStructReinvest;
            userPoolSeqID[userPoolList[_poolID][_poolRefSeqID]][_poolID].push(Auto_Pool_SeqID[_poolID]);
            userPoolList[_poolID][Auto_Pool_SeqID[_poolID]] = userPoolList[_poolID][_poolRefSeqID];
        }
        
        emit AutoPoolEvent(_poolRefSeqID,msg.sender, _poolID, now);    
    }
    
    
    function autoPoolUplines(
        address _user,
        uint _poolID,
        uint _userPoolID
        )
        internal
    {
        address[10] memory  uplineUsers;
        uint[10] memory uplineUsersID;
        uplineUsers[0] =  userPoolList[_poolID][usersPool[_user][_poolID][_userPoolID].poolReferrerID];
        uplineUsersID[0] = usersPool[_user][_poolID][_userPoolID].poolReferrerID;
        uplineUsers[1] =  userPoolList[_poolID][usersPool[uplineUsers[0]][_poolID][uplineUsersID[0]].poolReferrerID];
        uplineUsersID[1] = usersPool[uplineUsers[0]][_poolID][uplineUsersID[0]].poolReferrerID;
        uplineUsers[2] =  userPoolList[_poolID][usersPool[uplineUsers[1]][_poolID][uplineUsersID[1]].poolReferrerID];
        uplineUsersID[2] = usersPool[uplineUsers[1]][_poolID][uplineUsersID[1]].poolReferrerID;
        uplineUsers[3] =  userPoolList[_poolID][usersPool[uplineUsers[2]][_poolID][uplineUsersID[2]].poolReferrerID];
        uplineUsersID[3] = usersPool[uplineUsers[2]][_poolID][uplineUsersID[2]].poolReferrerID;
        uplineUsers[4] =  userPoolList[_poolID][usersPool[uplineUsers[3]][_poolID][uplineUsersID[3]].poolReferrerID];
        uplineUsersID[4] = usersPool[uplineUsers[3]][_poolID][uplineUsersID[3]].poolReferrerID;
        uplineUsers[5] =  userPoolList[_poolID][usersPool[uplineUsers[4]][_poolID][uplineUsersID[4]].poolReferrerID];
        uplineUsersID[5] = usersPool[uplineUsers[4]][_poolID][uplineUsersID[4]].poolReferrerID;
        uplineUsers[6] =  userPoolList[_poolID][usersPool[uplineUsers[5]][_poolID][uplineUsersID[5]].poolReferrerID];
        uplineUsersID[6] = usersPool[uplineUsers[5]][_poolID][uplineUsersID[5]].poolReferrerID;
        uplineUsers[7] =  userPoolList[_poolID][usersPool[uplineUsers[6]][_poolID][uplineUsersID[6]].poolReferrerID];
        uplineUsersID[7] = usersPool[uplineUsers[6]][_poolID][uplineUsersID[6]].poolReferrerID;
        uplineUsers[8] =  userPoolList[_poolID][usersPool[uplineUsers[7]][_poolID][uplineUsersID[7]].poolReferrerID];
        uplineUsersID[8] = usersPool[uplineUsers[7]][_poolID][uplineUsersID[7]].poolReferrerID;
        uplineUsers[9] =  userPoolList[_poolID][usersPool[uplineUsers[8]][_poolID][uplineUsersID[8]].poolReferrerID];
        uplineUsersID[9] = usersPool[uplineUsers[8]][_poolID][uplineUsersID[8]].poolReferrerID;
        
        for(uint i=0;i<10;i++){
            if(uplineUsers[i] == address(0)){
                uplineUsers[i] = userPoolList[_poolID][1];
                uplineUsersID[i] = 1;
            }
        }
        uint uplineAmount = Auto_Pool_Upline[_poolID];
        
        address(uint160(uplineUsers[0])).transfer(uplineAmount);
        address(uint160(uplineUsers[1])).transfer(uplineAmount);
        address(uint160(uplineUsers[2])).transfer(uplineAmount);
        address(uint160(uplineUsers[3])).transfer(uplineAmount);
        address(uint160(uplineUsers[4])).transfer(uplineAmount);
        address(uint160(uplineUsers[5])).transfer(uplineAmount);
        address(uint160(uplineUsers[6])).transfer(uplineAmount);
        address(uint160(uplineUsers[7])).transfer(uplineAmount);
        address(uint160(uplineUsers[8])).transfer(uplineAmount);
        address(uint160(uplineUsers[9])).transfer(uplineAmount);
        admin.transfer(Auto_Pool_System[_poolID]);
        
        usersPool[uplineUsers[0]][_poolID][uplineUsersID[0]].totalEarning += uplineAmount;
        usersPool[uplineUsers[1]][_poolID][uplineUsersID[1]].totalEarning += uplineAmount;
        usersPool[uplineUsers[2]][_poolID][uplineUsersID[2]].totalEarning += uplineAmount;
        usersPool[uplineUsers[3]][_poolID][uplineUsersID[3]].totalEarning += uplineAmount;
        usersPool[uplineUsers[4]][_poolID][uplineUsersID[4]].totalEarning += uplineAmount;
        usersPool[uplineUsers[5]][_poolID][uplineUsersID[5]].totalEarning += uplineAmount;
        usersPool[uplineUsers[6]][_poolID][uplineUsersID[6]].totalEarning += uplineAmount;
        usersPool[uplineUsers[7]][_poolID][uplineUsersID[7]].totalEarning += uplineAmount;
        usersPool[uplineUsers[8]][_poolID][uplineUsersID[8]].totalEarning += uplineAmount;
        usersPool[uplineUsers[9]][_poolID][uplineUsersID[9]].totalEarning += uplineAmount;
        usersPool[admin][_poolID][1].totalEarning += Auto_Pool_System[_poolID];
        emit AutoPoolUplineEvent(usersPool[_user][_poolID][_userPoolID].poolReferrerID,_poolID,msg.sender, uplineUsers);
       
    }
    
    function viewUserReferral(address _user) public view returns(address[] memory) {
        return users[_user].referral;
    }
    
    function viewUserPoolReferral(address _user,uint _poolID,uint _userPoolID) public view returns(address[] memory) {
        return usersPool[_user][_poolID][_userPoolID].poolReferral;
    }
    
    function viewUserPoolSeqID(address _user,uint _poolID)public view returns(uint[] memory) {
        return userPoolSeqID[_user][_poolID];
    }
    
    function contractLock(bool _lockStatus) public returns (bool) {
        require(msg.sender == admin, "Invalid User");

        lockStatus = _lockStatus;
        return true;
    }
    
    function failSafe(address payable _toUser, uint _amount) public returns (bool) {
        require(msg.sender == admin, "only Owner Wallet");
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");

        (_toUser).transfer(_amount);
        return true;
    }
    
}