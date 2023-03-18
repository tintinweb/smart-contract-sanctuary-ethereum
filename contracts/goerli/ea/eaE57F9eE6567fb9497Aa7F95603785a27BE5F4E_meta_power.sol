/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17; 

//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
contract owned
{
    address internal owner;
    address internal newOwner;
    address public signer;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
        signer = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    modifier onlySigner {
        require(msg.sender == signer, 'caller must be signer');
        _;
    }


    function changeSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}



//*******************************************************************//
//------------------         token interface        -------------------//
//*******************************************************************//

 interface tokenInterface
 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
 }



//*******************************************************************//
//------------------        MAIN contract         -------------------//
//*******************************************************************//

contract meta_power is owned {


    uint public minInvestAmount;
    uint public maxInvestAmount;
    address public firstInvestor;
    address public tokenAddress;
    uint public oneDay = 180 seconds; // this can be changed for testing,  like '30 min' , '100' etc
    uint public maxPayout = 25000; // = 250%

     struct userInfo {
        uint joinTime;
        address referrer;
        uint investedAmount;
        uint returnPercent;
        uint lastWithdrawTime;
        uint totalPaidROI;
        uint totalPaid;
        uint totalBusiness;
    }

    mapping ( address => userInfo) public userInfos;
    mapping ( address => address[]) public referred;
    mapping ( address => bool[10]) public bonus; // 
    mapping ( address => uint[10]) public lastBonusTime; // 
    mapping ( address => uint[10]) public totalBonusPaid; //
    mapping (address => uint) public referralWithdraw;
    mapping (address => uint) public mentorGain;



    mapping (address => uint[]) public investRecords;
    mapping (address => uint[]) public roiPaidRecords;
    mapping (address => uint[]) public payTimeRecords;


    uint public defaultROI = 50 ; // equal to 0.5% daily 
                             
    uint public div = 10 ** 4; // for roi percent calculation
    uint[10] public levelIncome; // values in percent
    uint[10] public mentorROI; // values in percent
    uint[10] public bonusTarget; // values in percent
    uint[10] public rewardBonus; // values in percent

    constructor () {
        levelIncome[0] = 1000; // for level 1
        levelIncome[1] = 200; // for level 2
        levelIncome[2] = 100; // for level 3
        levelIncome[3] = 100; // for level 4
        levelIncome[4] = 50; // for level 5
        levelIncome[5] = 50; // for level 6
        levelIncome[6] = 25; // for level 7
        levelIncome[7] = 25; // for level 8
        levelIncome[8] = 25; // for level 9
        levelIncome[9] = 25; // for level 10

        mentorROI[0] = 1500; // for level 1
        mentorROI[1] = 1000; // for level 2
        mentorROI[2] = 100; // for level 3
        mentorROI[3] = 400; // for level 4
        mentorROI[4] = 200; // for level 5
        mentorROI[5] = 200; // for level 6
        mentorROI[6] = 300; // for level 7
        mentorROI[7] = 400; // for level 8
        mentorROI[8] = 200; // for level 9
        mentorROI[9] = 300; // for level 10

        bonusTarget[0] = 2000 * (10 ** 18); // for level 1
        bonusTarget[1] = 5000 * (10 ** 18); // for level 2
        bonusTarget[2] = 15000 * (10 ** 18); // for level 3
        bonusTarget[3] = 35000 * (10 ** 18); // for level 4
        bonusTarget[4] = 90000 * (10 ** 18); // for level 5
        bonusTarget[5] = 150000 * (10 ** 18); // for level 6
        bonusTarget[6] = 300000 * (10 ** 18); // for level 7
        bonusTarget[7] = 600000 * (10 ** 18); // for level 8
        bonusTarget[8] = 1000000 * (10 ** 18); // for level 9
        bonusTarget[9] = 1500000 * (10 ** 18); // for level 10

        rewardBonus[0] = 1 * (10 ** 18); // for level 1
        rewardBonus[1] = 25 * (10 ** 17); // for level 2
        rewardBonus[2] = 11 * (10 ** 18); // for level 3
        rewardBonus[3] = 24 * (10 ** 18); // for level 4
        rewardBonus[4] = 55 * (10 ** 18); // for level 5
        rewardBonus[5] = 120 * (10 ** 18); // for level 6
        rewardBonus[6] = 240 * (10 ** 18); // for level 7
        rewardBonus[7] = 440 * (10 ** 18); // for level 8
        rewardBonus[8] = 740 * (10 ** 18); // for level 9
        rewardBonus[9] = 1001 * (10 ** 18); // for level 10

        userInfo memory UserInfo;

        UserInfo = userInfo({
            joinTime: block.timestamp,
            referrer: msg.sender,
            investedAmount: 1,  
            returnPercent: defaultROI,
            lastWithdrawTime: block.timestamp,
            totalPaidROI: 0,
            totalPaid:0,
            totalBusiness:0
        });
        userInfos[msg.sender] = UserInfo;
        firstInvestor = msg.sender;
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner returns(bool){
        tokenAddress = _tokenAddress;
        return true;
    }

    function setInvestAmountCap(uint _min, uint _max) public onlyOwner returns(bool){
        minInvestAmount = _min;
        maxInvestAmount = _max;
        return true;
    }

    event newJnvestEv(address user, address referrer,uint amount,uint eventTime);
    event directPaidEv(address paidTo,uint level,uint amount,address user,uint eventTime);
    event bonusEv(address receiver,address sender,uint newPercent,uint eventTime);

    function firstInvest(address _referrer, uint _amount) public returns(bool) {
        require(userInfos[msg.sender].joinTime == 0, "already invested");
        require(userInfos[_referrer].joinTime > 0, "Invalid referrer");
        require(_amount >= minInvestAmount && _amount <= maxInvestAmount, "Invalid Amount");
        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), _amount);

        userInfo memory UserInfo;

        UserInfo = userInfo({
            joinTime: block.timestamp,
            referrer: _referrer,
            investedAmount: _amount,  
            returnPercent: defaultROI,
            lastWithdrawTime: block.timestamp,
            totalPaidROI: 0,
            totalPaid:0,
            totalBusiness: 0
        });
        userInfos[msg.sender] = UserInfo;
        referred[_referrer].push(msg.sender);

        emit newJnvestEv(msg.sender, _referrer, _amount, block.timestamp);


        // pay direct
        address _ref = _referrer;
        for(uint i=0;i<10;i++) {
            userInfos[_ref].totalBusiness += _amount;
            uint amt = _amount * levelIncome[i] / 10000;
            //tokenInterface(tokenAddress).transfer(_ref,amt);
            referralWithdraw[_ref] += amt;
            emit directPaidEv(_ref, i, amt, msg.sender, block.timestamp);
            _ref = userInfos[_ref].referrer;
        }

        userInfo memory temp = userInfos[_referrer];
        //if booster
        if(block.timestamp - temp.joinTime <= 30 * oneDay && _amount >= temp.investedAmount && _amount > (100 * (10 ** 18)) && temp.returnPercent < 125 ) {
            temp.returnPercent = temp.returnPercent + 10; // increase = 0.1 % daily 
            if ( temp.returnPercent > 100 )  temp.returnPercent = 125; // persecond increase = 1.25 %
            emit bonusEv(_referrer, msg.sender, temp.returnPercent, block.timestamp);
            userInfos[_referrer].returnPercent = temp.returnPercent;
        }

        return true;
    }

    function withdraw(address forUser) public returns(bool) {
        withdrawReferral(forUser);
        withdrawROI(forUser);
        withdrawBonus(forUser);
        withdrawMentorGain(forUser);
        return true;
    }

    function withdrawReferral(address forUser) public returns(bool) {
        uint amt = referralWithdraw[forUser];
        referralWithdraw[forUser] = 0;
        tokenInterface(tokenAddress).transfer(forUser,amt);        
        return true;
    }

    event withdrawEv(address caller,uint roiAmount,uint forDay,uint percent, uint eventTime );
    event mentorPaidEv(address paidTo,uint level,uint amount,address user,uint eventTime);
    function withdrawROI(address forUser) public returns(bool) {
        userInfo memory temp = userInfos[forUser];       
        if(temp.totalPaid < temp.investedAmount * maxPayout / 10000 ) {
            uint totalDays = (block.timestamp - temp.lastWithdrawTime) / oneDay;
            if (totalDays > 0) {
                uint roiAmount = totalDays *  temp.investedAmount *  temp.returnPercent / div;
                
                // chek for max pay limit
                if ( temp.totalPaid + roiAmount > temp.investedAmount  * maxPayout / 10000  ) roiAmount = (temp.investedAmount * maxPayout / 10000 ) - temp.totalPaid;
                userInfos[forUser].totalPaid += roiAmount;

                userInfos[forUser].totalPaidROI += roiAmount;
                userInfos[forUser].lastWithdrawTime = block.timestamp;
                tokenInterface(tokenAddress).transfer(forUser,roiAmount);
                emit withdrawEv(forUser, roiAmount, totalDays,temp.returnPercent, block.timestamp );

                // pay mentor
                address _ref = userInfos[forUser].referrer;
                for(uint i=0;i<10;i++) {
                    uint amt = roiAmount * mentorROI[i] / 10000;
                    mentorGain[_ref] += amt;
                    //tokenInterface(tokenAddress).transfer(_ref,amt);
                    emit mentorPaidEv(_ref, i, amt, forUser, block.timestamp);
                    _ref = userInfos[_ref].referrer;
                }                
                
            }
        }
        return true;
    }

    function withdrawMentorGain(address forUser) public returns(bool) {
        if (mentorGain[forUser] > 0) {
            uint amt = mentorGain[forUser];
            mentorGain[forUser] = 0;

            // chek for max pay limit
            userInfo memory temp = userInfos[forUser];
            if ( temp.totalPaid + amt > temp.investedAmount  * maxPayout / 10000  ) amt = (temp.investedAmount * maxPayout / 10000 ) - temp.totalPaid;
            userInfos[forUser].totalPaid += amt;

            tokenInterface(tokenAddress).transfer(forUser,amt);
        }
        return true;
    }

    function viewMyROI(address forUser) public view returns(uint) {
        uint roiAmount;
        userInfo memory temp = userInfos[forUser];       
        if(temp.totalPaid < temp.investedAmount *  maxPayout / 10000) {
            uint totalDays = ( block.timestamp - temp.lastWithdrawTime ) / oneDay;
            if (totalDays > 0) {
                roiAmount = totalDays *  temp.investedAmount *  temp.returnPercent / div;
                if ( temp.totalPaid + roiAmount > temp.investedAmount * maxPayout / 10000 ) roiAmount = (temp.investedAmount * maxPayout / 10000) - temp.totalPaid;              
            }
        }
        return roiAmount;
    }    


    function claimRewardBonus() public returns(bool) {
        for(uint i=0;i<10;i++) {
            if (!bonus[msg.sender][i]) {
                if(userInfos[msg.sender].totalBusiness >= bonusTarget[i] && eligible(msg.sender,bonusTarget[i])) {
                    bonus[msg.sender][i] = true;
                    lastBonusTime[msg.sender][i] = block.timestamp;
                    break;
                }
            }
        }
        return true;
    }

    function eligible(address _user, uint amount) public view returns(bool) {
        uint sum;
        uint len = referred[_user].length;
        address _ref;
        for(uint i=0;i<len;i++) {
            _ref = referred[_user][i];
            if(userInfos[_ref].totalBusiness >= amount * 4/10 && ( sum == 0 || sum == 3 || sum == 6 )) sum += 4;
            else if (userInfos[_ref].totalBusiness >= amount * 3/10) sum += 3;
            if(sum == 10) break;
        }
        if(sum==10) return true;
        else return false;

    }

    event withdrawBonusEv(address user,uint totalBonus,uint eventTime);
    function withdrawBonus(address forUser) public returns(bool) {
        uint totalBonus;
        for(uint i=0;i<10;i++) {
            uint bp = totalBonusPaid[forUser][i];
            if (bonus[forUser][i] && bp > 150 * rewardBonus[i]) {
                uint day = ( block.timestamp - lastBonusTime[forUser][i] ) / oneDay ;
                totalBonus += rewardBonus[i] * day;
                if(bp + totalBonus > 150 * rewardBonus[i]) totalBonus = (150 * rewardBonus[i]) - bp;
                totalBonusPaid[forUser][i] += totalBonus;
                lastBonusTime[forUser][i] = block.timestamp;
            }
        } 
        if(totalBonus > 0 ) {

            // chek for max pay limit
            userInfo memory temp  = userInfos[forUser];
            if ( temp.totalPaid + totalBonus > temp.investedAmount  * maxPayout / 10000  ) totalBonus = (temp.investedAmount * maxPayout / 10000 ) - temp.totalPaid;
            userInfos[forUser].totalPaid += totalBonus;
            tokenInterface(tokenAddress).transfer(forUser,totalBonus);
            emit withdrawBonusEv(forUser, totalBonus, block.timestamp);
        }       
        return true;
    }

    event nextInvestEv(address user, uint investIndex,uint amount,uint eventTime);
    function nextInvest(uint _amount) public returns(bool) {
        require(userInfos[msg.sender].joinTime > 0, "user not registered");

        require(_amount >= userInfos[msg.sender].investedAmount && _amount <= maxInvestAmount, "Invalid Amount");
        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), _amount);

        investRecords[msg.sender].push(_amount);
        roiPaidRecords[msg.sender].push(uint(0));
        payTimeRecords[msg.sender].push(block.timestamp);


        // pay direct
        address _ref = userInfos[msg.sender].referrer;
        for(uint i=0;i<10;i++) {
            userInfos[_ref].totalBusiness += _amount;
            uint amt = _amount * levelIncome[i] / 10000;
            //tokenInterface(tokenAddress).transfer(_ref,amt);
            referralWithdraw[_ref] += amt;
            emit directPaidEv(_ref, i, amt, msg.sender, block.timestamp);
            _ref = userInfos[_ref].referrer;
        }        

        emit nextInvestEv(msg.sender,investRecords[msg.sender].length -1, _amount, block.timestamp);
        return true;
    }


    event nextRoiWithdrawEv(address _user,uint _amt,uint _fromIndex,uint _toIndex,uint eventTime);
    function nextRoiWithdraw(uint fromIndex, uint toIndex) public returns(bool) {

        require(fromIndex <= toIndex && toIndex < investRecords[msg.sender].length, "Invalid Index");
        uint totalAmount;
        
        for(uint i=fromIndex; i<=toIndex; i++) {
            uint sec = block.timestamp - payTimeRecords[msg.sender][i];
            if (sec > 0) {
                uint invA = investRecords[msg.sender][i];
                uint amt = sec * invA * defaultROI / div;
                uint paidSoFar = roiPaidRecords[msg.sender][i];
                // chek for max pay limit
                if ( paidSoFar + amt > invA  * maxPayout / 10000  ) amt = (invA * maxPayout / 10000 ) - paidSoFar;
                payTimeRecords[msg.sender][i] = block.timestamp;
                roiPaidRecords[msg.sender][i] += amt;
                totalAmount += amt;
            }

        }

        // pay mentor
        address _ref = userInfos[msg.sender].referrer;
        for(uint i=0;i<10;i++) {
            uint amt = totalAmount * mentorROI[i] / 10000;
            mentorGain[_ref] += amt;
            emit mentorPaidEv(_ref, i, amt, msg.sender, block.timestamp);
            _ref = userInfos[_ref].referrer;
        } 

        tokenInterface(tokenAddress).transfer(msg.sender, totalAmount);
        emit nextRoiWithdrawEv(msg.sender, totalAmount,fromIndex, toIndex, block.timestamp);
        return true;
    }


    function viewNextRoiWithdraw(uint fromIndex, uint toIndex, address user) public view returns(uint) {
        uint totalAmount;
        if(fromIndex <= toIndex && toIndex < investRecords[user].length){


            for(uint i=fromIndex; i<=toIndex; i++) {
                uint sec = block.timestamp - payTimeRecords[user][i];
                if (sec > 0) {
                    uint invA = investRecords[user][i];
                    uint amt = sec * invA * defaultROI / div;
                    uint paidSoFar = roiPaidRecords[user][i];
                    // chek for max pay limit
                    if ( paidSoFar + amt > invA  * maxPayout / 10000  ) amt = (invA * maxPayout / 10000 ) - paidSoFar;
                    totalAmount += amt;
                }
            }
        }

        return totalAmount;
    }


}