/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

// File: Name.sol


// The contract for the best ever game on BSC
/*
  /$$$$$$                                  /$$                      /$$$$$$
 /$$__  $$                                | $$                     /$$__  $$
| $$  \__/  /$$$$$$  /$$   /$$  /$$$$$$  /$$$$$$    /$$$$$$       | $$  \__/  /$$$$$$   /$$$$$$   /$$$$$$$  /$$$$$$ 
| $$       /$$__  $$| $$  | $$ /$$__  $$|_  $$_/   /$$__  $$      |  $$$$$$  /$$__  $$ |____  $$ /$$_____/ /$$__  $$
| $$      | $$  \__/| $$  | $$| $$  \ $$  | $$    | $$  \ $$       \____  $$| $$  \ $$  /$$$$$$$| $$      | $$$$$$$$
| $$    $$| $$      | $$  | $$| $$  | $$  | $$ /$$| $$  | $$       /$$  \ $$| $$  | $$ /$$__  $$| $$      | $$_____/
|  $$$$$$/| $$      |  $$$$$$$| $$$$$$$/  |  $$$$/|  $$$$$$/      |  $$$$$$/| $$$$$$$/|  $$$$$$$|  $$$$$$$|  $$$$$$$
 \______/ |__/       \____  $$| $$____/    \___/   \______/        \______/ | $$____/  \_______/ \_______/ \_______/
                     /$$  | $$| $$                                          | $$
                    |  $$$$$$/| $$                                          | $$
                     \______/ |__/                                          |__/

*/
//SPDX-License-Identifier:MIT

pragma solidity ^0.8.9;

contract CryptoSpace{

    struct User{
        uint id;
        address ref;
        uint lvlInRow;
        uint extraBR;
        mapping(uint=>uint) lostMoney;
        mapping(uint=>uint) frzdRefReward;
        mapping(uint=>bool) lvlWasAct;
        mapping(uint=>bool) lvlIsAct;
        mapping(uint=>uint) place;
        mapping(uint=>uint) AbsPlace;
        mapping(uint=>uint) usersBP;
        mapping(uint=>bool) Insurance;
        mapping(uint=>uint) gottenRewards;
        mapping(uint=>uint) gottenRefReward;
        mapping(uint=>uint) reinvests;
    }

    struct Structure{
        uint StrId;
        address mainStrLvl;
        address[4] firstStrLvl;
        address[6] secondStrLvl;
        uint freePlace;
    }

    struct Level{
    uint freeAbsPlace;
    mapping(uint=>Structure) idToStr;
    }

    uint constant lastLvl=15;
    uint lastUserId=5;
    uint registrationCost=700000000000 wei;
    uint public startProjectTime;
    bool insuranceWasSent;

    mapping(uint=>Level) lvlToStr;
    mapping(address=>User) users;
    mapping(uint=>address) idToAddr;
    mapping(uint=>uint) freeSecondLvl;
    mapping(uint=>uint) freeFirstLvl;
    bool[16] public lvlIsAv;
    mapping(uint=>mapping (uint=>address)) pAddr;
    mapping(uint=>mapping (address=>uint)) wRR;
    mapping(uint=>mapping (uint=>uint)) wRRId;
    mapping(uint=>bool) expLvl;
    mapping(uint=>uint) nOfPA;
    mapping(uint=>uint) levelStartTime;
    mapping(uint=>uint) refRewardsSendTime;
    mapping(uint=>uint) usersAtLvl;
    mapping(uint=>uint) reinvCount;

    mapping(uint=>uint) public lvlPrice;
    mapping (uint=>uint) public BRPercent;
    mapping (uint=>uint) public refPercent;

    mapping(uint=>address) owners;

    event Registration(address indexed user, address indexed referrer, uint userId, uint referrerId);
    event NewUserPlace(address indexed user, uint indexed structure, uint level, uint place, bool indexed insurance);

    constructor(address ownerAddr, address ownerAddr1, address ownerAddr2, address ownerAddr3, address ownerAddr4, address insuranceAddr, address marketingAddr){
        serValues();
        startProjectTime=block.timestamp;
        owners[1]=ownerAddr;
        owners[2]=ownerAddr1;
        owners[3]=ownerAddr2;
        owners[4]=ownerAddr3;
        owners[5]=ownerAddr4;
        owners[6]=insuranceAddr;
        owners[7]=marketingAddr;

        Structure memory structure=Structure({
            StrId:1,
            mainStrLvl:owners[1],
            firstStrLvl:[owners[2],owners[3],owners[4],owners[5]],
            secondStrLvl:[address(0),address(0),address(0),address(0),address(0),address(0)],
            freePlace:6
        });

        for (uint i=1; i<=5; i++){
            users[owners[i]].id=i;
        users[owners[i]].ref=owners[i];
        users[owners[i]].lvlInRow=15;
        idToAddr[i]=owners[i];
        }

       for (uint i = 1; i <= lastLvl; i++){
           for (uint j=1; j<=5; j++){
               users[owners[j]].lvlWasAct[i]=true;
               users[owners[j]].lvlIsAct[i]=true;
               users[owners[j]].place[i]=j;
               users[owners[j]].AbsPlace[i]=j;
           }
           lvlToStr[i].idToStr[1]=structure;
           lvlToStr[i].freeAbsPlace=6;
           usersAtLvl[i]=5;
       }
    }

    modifier onlyOwner(){
      require(owners[1]==msg.sender, "only owner");
      _;
    }

    modifier levelIsOpen(uint lvl){
      require(block.timestamp>=levelStartTime[lvl] && levelStartTime[lvl]>0, "level closed");
      _;
    }

    function registration(address refAddr) external payable{
        registrationInt(msg.sender, refAddr);
    }

    function registrationInt(address user, address refAddr) private{
        require(msg.value==registrationCost, "wrong value");
        require(!isUserExists(user), "user already exists");
        require(isUserExists(refAddr), "refUser doesn't exist");

        sendOnInsuranceAddr(0);        
        lastUserId++;
        users[user].id=lastUserId;
        idToAddr[lastUserId]=user;
        users[user].ref=refAddr;
        emit Registration(user, refAddr, lastUserId, users[refAddr].id);
    }

    function buyNewLevel(uint lvl) public payable levelIsOpen(lvl){
        if (!lvlIsAv[lvl]){
            _openLevel(lvl);
        }
        address user=msg.sender;
        uint _levelPrice=lvlPrice[lvl];
        if (users[user].Insurance[lvl]){
            _levelPrice+=(_levelPrice*5/100);
        }
        require(isUserExists(user), "user doesn't exist");
        require(lvl>0 && lvl<=lastLvl, "wrong level");
        require(!users[user].lvlIsAct[lvl], "level is already active");
        require(msg.value==_levelPrice, "wrong value");
        usersAtLvl[lvl]++;
        if (users[user].Insurance[lvl]){
         sendOnInsuranceAddr(lvl);
        }

        users[user].lvlIsAct[lvl]=true;
        users[user].lvlWasAct[lvl]=true;
        users[user].reinvests[lvl]=reinvCount[lvl];

        uint _lvlInRow;
        for (uint i=1; i<=15; i++){
           if (users[user].lvlIsAct[i]==false){
                break;
            }
            _lvlInRow=i;
        }
        users[user].lvlInRow=_lvlInRow;
        if (_lvlInRow>8){
            users[user].extraBR=BRPercent[_lvlInRow];
        }
        updateStructure(user, freeSecondLvl[lvl], lvl);
    }

     function buyNewLevelWithInsurance(uint lvl) external payable levelIsOpen(lvl){
         require(!insuranceWasSent, "not available");
        users[msg.sender].Insurance[lvl]=true;
        buyNewLevel(lvl);
    }

    function paymentOfInsurance() external onlyOwner{
        insuranceWasSent=true;
        for (uint i=6; i<=lastUserId; i++){
            uint InsurancePayment=0;
            for (uint j=1; j<=lastLvl; j++){
                if (users[idToAddr[i]].Insurance[j]){
                   InsurancePayment+=lvlPrice[j]*20/100;
                }
            }
            if (InsurancePayment>0){
               writeInsuranceDates(InsurancePayment, idToAddr[i]);
            }
        }
        paymentCall();
    }

    function writeInsuranceDates(uint Ipayment, address Iaddress) private{
        (bool success, bytes memory data)=owners[6].call(abi.encodeWithSignature("writeInsuranceDates(uint256,address)", Ipayment, Iaddress));
    }

    function paymentCall() private{
        (bool success, bytes memory data)=owners[6].call(abi.encodeWithSignature("payment()"));
    }

    function setInsuranceAddress(address newInsAddr) external onlyOwner{
        owners[6]=newInsAddr;
    }

    function setMarkettingAddress(address newMarketingAddr) external onlyOwner{
        owners[7]=newMarketingAddr;
    }

    function setlevelStartTime(uint lvl, uint time) external onlyOwner{
        levelStartTime[lvl]=time;
    }

    function _openLevel(uint lvl) internal{
        lvlIsAv[lvl]=true;
        expLvl[lvl]=true;
        refRewardsSendTime[lvl]=block.timestamp+600;
    }

    function sendFreezedReferralRewards(uint lvl) external onlyOwner{
        require(block.timestamp >= refRewardsSendTime[lvl], "early"); 
        require(refRewardsSendTime[lvl]>0, "not available"); 
        expLvl[lvl]=false;
        if (nOfPA[lvl]>0){
            sendFrzdRefRewInt(lvl);
        }
    }

    function updateStructure(address user, uint StrId, uint lvl) private{
        users[user].place[lvl]=lvlToStr[lvl].idToStr[StrId].freePlace;
        users[user].AbsPlace[lvl]=lvlToStr[lvl].freeAbsPlace;
        users[user].usersBP[lvl]=usersBeforeFirstPandingCounter(user, lvl);

        lvlToStr[lvl].idToStr[StrId].secondStrLvl[(lvlToStr[lvl].idToStr[StrId].freePlace)-6]=user;
        lvlToStr[lvl].idToStr[StrId].freePlace++;
        lvlToStr[lvl].freeAbsPlace++;
        sendRewards(user, StrId, lvl);
        emit NewUserPlace(user, StrId, lvl, users[user].place[lvl], users[user].Insurance[lvl]);
        if (lvlToStr[lvl].idToStr[StrId].freePlace==12){
            upgradeStructure(StrId, lvl);
        }
    }

    function upgradeStructure(uint256 StrId, uint lvl) private{

        for(uint i=0; i<4; i++){
            address newMainStrLvl=lvlToStr[lvl].idToStr[StrId].firstStrLvl[i];
            uint256 newMatrixId=users[newMainStrLvl].AbsPlace[lvl];
            Structure memory structure=Structure({
                StrId:newMatrixId,
                mainStrLvl:newMainStrLvl,
                firstStrLvl:[address(0),address(0),address(0),address(0)],
                secondStrLvl:[address(0),address(0),address(0),address(0),address(0),address(0)],
                freePlace:2
            });
            lvlToStr[lvl].idToStr[newMatrixId]=structure;
            users[newMainStrLvl].place[lvl]=1;
        }

        address mainAddr=lvlToStr[lvl].idToStr[StrId].mainStrLvl;
        uint _freePlace=lvlToStr[lvl].idToStr[freeFirstLvl[lvl]].freePlace;

        for (uint i=0; i<6; i++){
             if (_freePlace>5){
                 freeFirstLvl[lvl]++;
                 _freePlace=lvlToStr[lvl].idToStr[freeFirstLvl[lvl]].freePlace;
             }
             lvlToStr[lvl].idToStr[freeFirstLvl[lvl]].firstStrLvl[_freePlace-2]=lvlToStr[lvl].idToStr[StrId].secondStrLvl[i];
             users[lvlToStr[lvl].idToStr[freeFirstLvl[lvl]].firstStrLvl[_freePlace-2]].place[lvl]=_freePlace;
             lvlToStr[lvl].idToStr[freeFirstLvl[lvl]].freePlace++;
             _freePlace++;
        }

        if (users[mainAddr].id<6){
             if (_freePlace>5){
                 freeFirstLvl[lvl]++;
                 _freePlace=lvlToStr[lvl].idToStr[freeFirstLvl[lvl]].freePlace;
             }
            lvlToStr[lvl].idToStr[freeFirstLvl[lvl]].firstStrLvl[_freePlace-2]=mainAddr;
            users[mainAddr].place[lvl]=_freePlace;
            users[mainAddr].AbsPlace[lvl]=lvlToStr[lvl].freeAbsPlace;
            lvlToStr[lvl].freeAbsPlace++;
            lvlToStr[lvl].idToStr[freeFirstLvl[lvl]].freePlace++;
            reinvCount[lvl]++;
        }else{
            users[mainAddr].lvlIsAct[lvl]=false;
            users[mainAddr].place[lvl]=0;
            users[mainAddr].AbsPlace[lvl]=0;
            uint _lvlInRow=users[mainAddr].lvlInRow;
            if (_lvlInRow>8 && lvl<=_lvlInRow){
                users[mainAddr].lvlInRow=lvl-1;
                if (users[mainAddr].lvlInRow>8){
                    users[mainAddr].extraBR=BRPercent[_lvlInRow];
                }else{
                    users[mainAddr].extraBR=0;
                }
            }
        }
        freeSecondLvl[lvl]++;
    }

    function sendRewards(address user, uint256 StrId, uint lvl) private{
        address payable rec;
        if (users[user].place[lvl]==11){
              rec=payable(lvlToStr[lvl].idToStr[StrId].mainStrLvl);
              users[rec].usersBP[lvl]=0;
        }else{
              if (users[user].place[lvl]==8){
                  rec=payable(lvlToStr[lvl].idToStr[StrId].mainStrLvl);
                  users[rec].usersBP[lvl]=3;
              }else{
                    if (users[user].place[lvl]<8){
                        rec=payable(lvlToStr[lvl].idToStr[StrId].firstStrLvl[users[user].place[lvl]-6]);
                    }else{
                        rec=payable(lvlToStr[lvl].idToStr[StrId].firstStrLvl[users[user].place[lvl]-7]);
                       }
                    users[rec].Insurance[lvl]=false;
                    users[rec].usersBP[lvl]=usersBeforeSecondPandingCounter(rec, lvl);
              }
        }

        uint BR;
        if (users[rec].extraBR>0){
            BR=users[rec].extraBR;
            }else{
                BR=BRPercent[lvl];
            }
        rec.transfer(lvlPrice[lvl]*BR/100);
        users[rec].gottenRewards[lvl]+=lvlPrice[lvl]*BR/100;

        if (expLvl[lvl]&&refRewardsSendTime[lvl]>block.timestamp&&refRewardsSendTime[lvl]>0){
            uint n=1;
            address nextRef=user;
            while (n<=7){
                address _ref=users[nextRef].ref;
                if (users[_ref].lvlWasAct[lvl]){
                    n++;
                    nextRef=_ref;
                }else{
                    break;
                }
            }
            if (n==8){
                sendRefRew(user,lvl);
            }else{
                nOfPA[lvl]++;
                pAddr[lvl][nOfPA[lvl]]=user;
                uint i=1;
                address _nextReferrer=user;
                while (i<=7){
                    address _ref=users[_nextReferrer].ref;
                    if (users[_ref].lvlWasAct[lvl]){
                        i++;
                    }else{
                        users[_ref].frzdRefReward[lvl]+=lvlPrice[lvl]*refPercent[i]/100;
                    }
                    _nextReferrer=_ref;
                }
            }
        } else{
            sendRefRew(user, lvl);
        }
        address payable _marketing=payable(owners[7]);
        uint marketingPercent=(77-BR);
        _marketing.transfer(lvlPrice[lvl]*marketingPercent/100);
    }

    function sendRefRew(address user, uint lvl) private{
        address nextRef=user;
        uint j=1;
        while (j<=7){
            address payable _ref = payable(users[nextRef].ref);
            if (users[_ref].lvlWasAct[lvl]){
                _ref.transfer(lvlPrice[lvl]*refPercent[j]/100);
                users[_ref].gottenRefReward[lvl]+=lvlPrice[lvl]*refPercent[j]/100;
                j++;
            }else{
                users[_ref].lostMoney[lvl]+=lvlPrice[lvl]*refPercent[j]/100;
            }
            nextRef=_ref;
        }
    }

    function sendFrzdRefRewInt(uint lvl) private{
        uint num;
        for (uint i=1; i<=nOfPA[lvl]; i++){ 
            address nextRef=pAddr[lvl][i];
            uint j=1;
            while (j<=7){
                address payable _ref=payable(users[nextRef].ref);
                if (users[_ref].lvlWasAct[lvl]){
                    users[_ref].frzdRefReward[lvl]=0;
                    if (wRR[lvl][_ref]==0){
                        num++;
                        wRRId[lvl][num]+=users[_ref].id;
                    }
                    wRR[lvl][_ref]+=lvlPrice[lvl]*refPercent[j]/100;
                    users[_ref].gottenRefReward[lvl]+=lvlPrice[lvl]*refPercent[j]/100;
                    j++;
                } else{
                    users[_ref].lostMoney[lvl]+=lvlPrice[lvl]*refPercent[j]/100;
                }
                nextRef=_ref;
            }
        }

        for (uint k=1; k<=num; k++){
                address payable rec=payable (idToAddr[wRRId[lvl][k]]);
                uint amount=wRR[lvl][rec];
                rec.transfer(amount);
        }
    }

    function sendOnInsuranceAddr(uint lvl) private{
        address payable rec=payable(owners[6]);
        if (lvl==0){
            rec.transfer(registrationCost);
        }else{
        rec.transfer(lvlPrice[lvl]*5/100);
        }
    }

    function isUserExists(address user) public view returns (bool){
        return(users[user].id!=0);
    }

    function usersBeforeFirstPandingCounter(address user, uint lvl) private view returns (uint){
        uint n=users[user].AbsPlace[lvl];
        if (n%2==0){
            return(((n-4)/2)+5+reinvCount[lvl]+(reinvCount[lvl]/2));
        }else{
        return(((n-5)/2)+5+reinvCount[lvl]+((reinvCount[lvl]+1)/2));
        }
    }

    function usersBeforeSecondPandingCounter(address user, uint lvl) private view returns (uint){
        return(6*(users[user].AbsPlace[lvl]-lvlToStr[lvl].idToStr[freeSecondLvl[lvl]].StrId-1)
        +15-lvlToStr[lvl].idToStr[freeSecondLvl[lvl]].freePlace);
    }

    function availableLevels() public onlyOwner view returns(bool[16] memory){
        return(lvlIsAv);
    }

    function getlevelPrices() public onlyOwner view returns(uint[16] memory levelPrices){
        uint[16] memory _levelPrices;
        for (uint i=1; i<16; i++){
            _levelPrices[i]=lvlPrice[i];
        }
        return(_levelPrices);
    }

    function userSiteDataes(address user) public onlyOwner view returns(uint extraBR, uint[16] memory lostMoney, bool[16] memory levelWasActivated, bool[16] memory levelIsActive, 
    uint[16] memory usersBP, bool[16] memory insurance, uint[16] memory userRewards, uint[16] memory userReferralRewards){
        address ad=user;
        uint[16] memory _lostMoney;
        bool[16] memory _levelWasActivated;
        bool[16] memory _levelIsActive;
        uint[16] memory _usersBeforePayment;
        bool[16] memory _insurance;
        uint[16] memory _userRewards;
        uint[16] memory _userReferralRewards;
        for (uint i=1; i<16; i++){
            _lostMoney[i]=users[ad].lostMoney[i];
            _levelWasActivated[i]=users[ad].lvlWasAct[i];
            _levelIsActive[i]=users[ad].lvlIsAct[i];
            _usersBeforePayment[i]=users[ad].usersBP[i];
            _insurance[i]=users[ad].Insurance[i];
            _userRewards[i]=users[ad].gottenRewards[i];
            _userReferralRewards[i]=users[ad].gottenRefReward[i];
        }
        return(users[ad].extraBR, _lostMoney, _levelWasActivated, _levelIsActive, _usersBeforePayment, _insurance, _userRewards, _userReferralRewards);
    }

    function userSiteDatesTwo(address user) public onlyOwner view returns(uint[16] memory freezedReferralReward){
        uint[16] memory _freezedReferralReward;
        for (uint i=1; i<16; i++){
            _freezedReferralReward[i]=users[user].frzdRefReward[i];
        }
        return (_freezedReferralReward);
    }

    function levelStartTimeDates() public onlyOwner view returns(uint[16] memory levelsStartTime){
        uint[16] memory _levelStartTime;
        for (uint i=1; i<16; i++){
            _levelStartTime[i]=levelStartTime[i];
        }
        return(_levelStartTime);
    }

    function paymentProgressDates(address user) public onlyOwner view returns(uint[16] memory userAbsolutePlace, uint[16] memory reinvest){
        uint[16] memory _userAbsolutePlace;
         uint[16] memory _reinvest;
        for (uint i=1; i<16; i++){
            _userAbsolutePlace[i]=users[user].AbsPlace[i];
            _reinvest[i]=users[user].reinvests[i];
        }
        return(_userAbsolutePlace, _reinvest);
    }

    function userAtLevelDates() public onlyOwner view returns(uint[16] memory usersAtTheLevel) {
        uint[16] memory _usersAtLvl;
        for (uint i=1; i<16; i++){
            _usersAtLvl[i]=usersAtLvl[i];
        }
        return(_usersAtLvl);
    }

    function serValues() private{
        BRPercent[1]=60;
        BRPercent[2]=60;
        BRPercent[3]=60;
        BRPercent[4]=60;
        BRPercent[5]=60;
        BRPercent[6]=60;
        BRPercent[7]=60;
        BRPercent[8]=60;
        BRPercent[9]=61;
        BRPercent[10]=63;
        BRPercent[11]=66;
        BRPercent[12]=69;
        BRPercent[13]=72;
        BRPercent[14]=76;
        BRPercent[15]=77;

        refPercent[1]=8;
        refPercent[2]=5;
        refPercent[3]=3;
        refPercent[4]=2;
        refPercent[5]=2;
        refPercent[6]=2;
        refPercent[7]=1;

        lvlPrice[1]=13000000000000 wei;
        lvlPrice[2]=17000000000000 wei; 
        lvlPrice[3]=24000000000000 wei;
        lvlPrice[4]=35000000000000 wei;
        lvlPrice[5]=50000000000000 wei;
        lvlPrice[6]=65000000000000 wei;
        lvlPrice[7]=90000000000000 wei;
        lvlPrice[8]=120000000000000 wei;
        lvlPrice[9]=170000000000000 wei;
        lvlPrice[10]=260000000000000 wei;
        lvlPrice[11]=390000000000000 wei;
        lvlPrice[12]=610000000000000 wei;
        lvlPrice[13]=960000000000000 wei;
        lvlPrice[14]=1400000000000000 wei;
        lvlPrice[15]=2200000000000000 wei;

        for (uint i = 1; i <= lastLvl; i++){
            freeSecondLvl[i] = 1;
            freeFirstLvl[i] = 2;
        }
    }
}