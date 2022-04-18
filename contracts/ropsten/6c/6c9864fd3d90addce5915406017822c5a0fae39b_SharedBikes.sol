// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import 'UserCentrol.sol';


contract SharedBikes {

    uint32 private _userCreditThreshold = 50;
    uint32 private _iniCredit = 60;
    uint256 private _BikePrice = 100;
    uint256 private  _upDamage = 40;
    address public admin;
    UserStorage public userStorage;
    MyToken public token;
    constructor(string memory _na ,string memory _sym , uint8 _deci,uint256 _initialSupply) payable {
        //require(msg.value==_initialSupply,"wei is not enough" );
        admin = msg.sender;
        token = new MyToken{value:msg.value}(_na,_sym,_deci,_initialSupply);
        userStorage = new UserStorage(address(this),token,_iniCredit);
    }
    
    modifier onlyAdmin(){
        require(msg.sender == admin, "admin required");
        _;
    }

    modifier userRegistered(address user){
        require(userStorage.exists(user), "user not registered");
        require(userStorage.activated(user), "user not activated");
        _;
    }

    modifier requireStatus(uint256 bikeId, BikeStatus bikeStatus){
        require(_bikes[bikeId].status == bikeStatus, "bad bike status");
        _;
    }

    modifier requireBikeId(uint256 bikeId){
        require(bikeId != 0, "illegal id");
        _;
    }

    struct Bike {
        BikeStatus status;
        uint health;
    }

    enum BikeStatus {
        NotExist,
        Available,
        InBorrow,
        InDamage,
        InRepair
    }

    event RegisterBike(uint256 indexed bikeId);
    event RevokeBike(uint256 indexed bikeId);
    event BorrowBike(address indexed borrower, uint256 indexed bikeId);
    event ReturnBike(address indexed borrower, uint256 indexed bikeId);
    event ReportDamage(address indexed reporter, uint256 indexed bikeId);
    event FixDamage(uint256 indexed bikeId);
    event Reward(address indexed borrower, uint32 credits);
    event Punish(address indexed borrower, uint32 credits);
    event SetCreditThreshold(uint32 newThreshold);
    event TransferAdmin(address oldAdmin, address newAdmin);
    event ChangeSysInfo(uint32 userCreditThreshold,uint32 iniCredit,uint256 iniCoin,uint256 upDamage);
    event BikeCentrolMint(uint256 amount);
    event BikeCentrolDestroy(uint256 amount);
    event Activate(address user);

    uint256 public _bikeCount;
    mapping(uint256=>Bike) private _bikes;
    mapping(address=>uint256) private _borrows;

    // 投放自行车
    function registerBike() external payable onlyAdmin returns(uint256 bikeId)  {
        _bikeCount++;
        bikeId = _bikeCount;
        token.destroy(_BikePrice);
        Bike storage bike = _bikes[bikeId];
        bike.status = BikeStatus.Available;
        bike.health = 100;
        emit RegisterBike(bikeId);
        emit BikeCentrolDestroy(_BikePrice);
    }

    function getSysInfo() external view returns(uint32 userCreditThreshold,uint32 iniCredit,uint256 BikePrice,uint256 upDamage){
          userCreditThreshold=_userCreditThreshold;
          iniCredit=_iniCredit;
          BikePrice=_BikePrice;
          upDamage=_upDamage;
    }

    function changeSysInfo(uint32 userCreditThreshold,uint32 iniCredit,uint256 BikePrice,uint256 upDamage) external onlyAdmin{
        _userCreditThreshold=userCreditThreshold;
        _iniCredit=iniCredit;
        _BikePrice=BikePrice;
        _upDamage=upDamage;
        emit ChangeSysInfo(userCreditThreshold,iniCredit,BikePrice,upDamage);
    }


    function getBikeInfo(uint256  bikeId) external requireBikeId(bikeId) view returns (BikeStatus  status , uint health){
        require(bikeId<=_bikeCount,"this bike is not existed");
        status = _bikes[bikeId].status;
        health = _bikes[bikeId].health;
    }

    //废除自行车
    function revokeBike(uint256 bikeId) external requireBikeId(bikeId) onlyAdmin {
        require(bikeId<=_bikeCount,"this bike is not existed");
        require(_bikes[bikeId].status != BikeStatus.InBorrow, "bad bike status");
        Bike storage bike = _bikes[bikeId];
        bike.status = BikeStatus.NotExist;
        emit RevokeBike(bikeId);
    }

    //激活用户
    function activateUser(address user) external onlyAdmin returns(bool success) {
        success = token.sendUserMoneny(user,_iniCredit);
        emit Activate(user);
        return userStorage.activateUser(user);
    }

    //用户借车
    function borrowBike(uint256 bikeId) external userRegistered(msg.sender) requireBikeId(bikeId) requireStatus(bikeId, BikeStatus.Available){
        require(_borrows[msg.sender] == 0 , "user in borrow");
        require(userStorage.getCredits(msg.sender) >= _userCreditThreshold, "not enough credits");
        _borrows[msg.sender] = bikeId;
        _bikes[bikeId].status = BikeStatus.InBorrow;
        emit BorrowBike(msg.sender, bikeId);
    }

    //用户还车
    function returnBike(uint256 bikeId) external  userRegistered(msg.sender) requireBikeId(bikeId) requireStatus(bikeId, BikeStatus.InBorrow){
        require(_borrows[msg.sender] == bikeId, "not borrowing this one");
        _borrows[msg.sender] = 0;
        Bike storage bike = _bikes[bikeId];
        bike.status = BikeStatus.Available;
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)))%_upDamage;
        uint256 newPoint = bike.health - random;
        require(newPoint < bike.health, "overflow");
        if(bike.health < random){
            bike.health = 0;
            token.getMoneyBack(msg.sender,bike.health);
            emit Punish(msg.sender,uint32(bike.health));
        }else{
            token.getMoneyBack(msg.sender,random);
            bike.health -=random;
             emit Punish(msg.sender,uint32(random));
        }
        if(bike.health <50){
            bike.status = BikeStatus.InDamage;
        }

        if(bike.health <30){
            bike.status = BikeStatus.NotExist;
        }
       emit ReturnBike(msg.sender, bikeId);
    }

    //报修
    function reportDamge(uint256 bikeId) external  userRegistered(msg.sender) requireBikeId(bikeId){
        require(bikeId<=_bikeCount,"this bike is not existed");
        require(_bikes[bikeId].status != BikeStatus.InBorrow, "bike is InBorrow");
        require(_bikes[bikeId].status != BikeStatus.InRepair, "bike is InRepair");
        require(_bikes[bikeId].status != BikeStatus.InRepair, "bike is NotExist");
        Bike storage bike = _bikes[bikeId];
        bike.status = BikeStatus.Available;
        uint256 rewardCount = 100- bike.health;
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)))%rewardCount;
        bike.health = 100;
        token.sendUserMoneny(msg.sender,random);
        uint256 newPoint = rewardCount-random;
        require(newPoint<rewardCount,"overflow");
        token.destroy(newPoint);
        emit BikeCentrolDestroy(_BikePrice);
        emit Reward(msg.sender, uint32(random));
        emit ReportDamage(msg.sender, bikeId);
    }

    
    //用户奖励
    function reward(address user, uint32 credits) external payable  userRegistered(user) onlyAdmin{
        require(credits > 0, "credits zero");
        uint256 newPoint = token.balanceOf(user) + credits;
        require(newPoint > credits, "overflow");
        token.sendUserMoneny(user,credits);
        emit Reward(user, credits);
    }

    //用户惩罚
    function punish(address user, uint32 credits) external   userRegistered(user) onlyAdmin{
        require(credits > 0, "credits zero"); 
        uint256 remand = token.balanceOf(user);
        uint256 newPoint =  remand - credits;
        require(newPoint < remand, "overflow");
        token.getMoneyBack(user,credits);
        emit Punish(user, credits);
    }

    //增发
    function mint( uint256 amount) public payable onlyAdmin virtual  returns (uint256) {
        uint256  temp = token._mint{value:msg.value}(amount);
        emit BikeCentrolMint(amount);
        return temp;
         
    }
}