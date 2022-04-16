// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import 'UserCentrol.sol';


contract SharedBikes {

    uint32 public userCreditThreshold = 50;
    uint32 public _iniCredit = 60;
    uint256 public addCoin = 5;
    address public admin;
    UserStorage public userStorage;
    MyToken public token;
    constructor(string memory _na ,string memory _sym , uint8 _deci,uint256 _initialSupply) {
        admin = msg.sender;
        token = new MyToken(_na,_sym,_deci,_initialSupply);
        userStorage = new UserStorage(address(this),token,_iniCredit);
    }
    
    modifier onlyAdmin(){
        require(msg.sender == admin, "admin required");
        _;
    }

    modifier userRegistered(address user){
        require(userStorage.exists(user), "user not registered");
        _;
    }

    modifier requireStatus(uint256 bikeId, BikeStatus bikeStatus){
        require(_bikes[bikeId].status == bikeStatus, "bad bike status");
        _;
    }

    struct Bike {
        BikeStatus status;
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

    uint256 private _bikeCount;
    mapping(uint256=>Bike) private _bikes;
    mapping(address=>uint256) private _borrows;

    // 投放自行车
    function registerBike() external onlyAdmin returns(uint256 bikeId) {
        _bikeCount++;
        bikeId = _bikeCount;
        token._mint(addCoin);
        Bike storage bike = _bikes[bikeId];
        bike.status = BikeStatus.Available;
        emit RegisterBike(bikeId);
    }

    //废除自行车
    function revokeBike(uint256 bikeId) external onlyAdmin requireStatus(bikeId, BikeStatus.Available){
        Bike storage bike = _bikes[bikeId];
        bike.status = BikeStatus.NotExist;
        emit RevokeBike(bikeId);
    }

    //用户借车
    function borrowBike(uint256 bikeId) external userRegistered(msg.sender) requireStatus(bikeId, BikeStatus.Available){
        require(_borrows[msg.sender] == 0, "user in borrow");
        require(userStorage.getCredits(msg.sender) >= userCreditThreshold, "not enough credits");
        _borrows[msg.sender] = bikeId;
        _bikes[bikeId].status = BikeStatus.InBorrow;
        emit BorrowBike(msg.sender, bikeId);
    }

    //用户还车
    function returnBike(uint256 bikeId) external  userRegistered(msg.sender) requireStatus(bikeId, BikeStatus.InBorrow){
        require(_borrows[msg.sender] == bikeId, "not borrowing this one");
        _borrows[msg.sender] = 0;
        Bike storage bike = _bikes[bikeId];
        bike.status = BikeStatus.Available;
        emit ReturnBike(msg.sender, bikeId);
    }

    //报修
    function reportDamge(uint256 bikeId) external  userRegistered(msg.sender) requireStatus(bikeId, BikeStatus.InDamage){
        Bike storage bike = _bikes[bikeId];
        bike.status = BikeStatus.InRepair;
        emit ReportDamage(msg.sender, bikeId);
    }

    //维修
    function fixDamge(uint256 bikeId) external onlyAdmin requireStatus(bikeId, BikeStatus.InRepair){
        Bike storage bike = _bikes[bikeId];
        bike.status = BikeStatus.Available;
    }
    
    //用户奖励
    function reward(address user, uint32 credits) external userRegistered(user) onlyAdmin{
        userStorage.addCredits(user, credits);
        emit Reward(user, credits);
    }

    //用户惩罚
    function punish(address user, uint32 credits) external userRegistered(user) onlyAdmin{
        userStorage.subCredits(user, credits);
        emit Punish(user, credits);
    }

    // 设计信誉阈值
    function setCreditThreshold(uint32 newThreshold) external onlyAdmin {
        userCreditThreshold = newThreshold;
        emit SetCreditThreshold(newThreshold);
    }
}