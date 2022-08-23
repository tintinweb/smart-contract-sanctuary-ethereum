/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract MELON{
    struct User{
        address reff;
        string position;
        string positionsetting;
    }

    mapping(address => bool) public isregister;
    mapping(address => User) private user;
    mapping(address => bool) public isbuy;


    // address public rewardaddress;
    bool public calculatebinaryincome;
    bool public refferstop;
    address public LeftOverBinary;
    address public RewardAddress;
    address public developmentFund;
    uint256 public MaxBinary;
    uint256 public reduceBinary;


    event registeruser(address _newaddress,address reffrence,address uplineaddress,string position);
    event Refferaddress(address directincome,uint256 amount,uint256 remaingamount,uint256 usdrefincome,uint256 TotalCount);
    event positionchange(address _A,string _a,uint256 timestamp);

    address public owner;
    address public admin;
    mapping(uint256 => bool) public isactivate;
    uint256 public totalcount;
    mapping(uint256 => uint256) public amount;
    constructor(address _developmentFund,address _LeftOverBinary,address _RewardAddress,address _admin){
        isregister[msg.sender] = true;
        calculatebinaryincome = true;
        refferstop = true;
        user[msg.sender].reff = address(0x0);
        user[msg.sender].position = "L";
        user[msg.sender].positionsetting = "L";
        owner = msg.sender;
        admin = _admin;
        developmentFund = _developmentFund;
        LeftOverBinary = _LeftOverBinary;
        RewardAddress = _RewardAddress;
    }
    function changereffer(bool _A)public returns(bool){
        require(owner == msg.sender,"is not admin");
        refferstop = _A;
        return true;
    }
    function getadmin() public view returns(address ){
        return admin;
    }

    function ChangeDevelopmentAddress(address _developmentFund)public returns(bool){
        require(owner == msg.sender,"is not admin");
        developmentFund = _developmentFund;
        return true;
    }
    function ChangeRewardAddress(address _A)public returns(bool){
        require(owner == msg.sender,"is not admin");
        RewardAddress = _A;
        return true;
    }
    function ChangeLeftOverBinary(address _A) public returns(bool){
        require(owner == msg.sender,"is not owner");
        LeftOverBinary = _A;
        return true;
    }
    function userdata(address _a)public view returns(User memory){
        return (user[_a]);
    }
    function givenmetoken(address _A)public returns(bool){
        require(owner == msg.sender,"is not admin call");
        payable(_A).transfer(address(this).balance);
        return true;
    }
    function changeposition(address _A,string memory _a)public returns(bool){
        require(isregister[_A],"user not register");
        require(keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked("R")) ||
                keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked("L")) ||
                keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked("A")),
                "Wrong Position Keyword");
        user[_A].positionsetting = _a;
        emit positionchange(_A,_a,block.timestamp);
        return true;
    }
    function checkuserregister(address _a)public view returns(bool){
        return isregister[_a];
    }
    function Register(address ref)public returns(bool){
        return Register(msg.sender,ref);
    }
    function Register(address _user,address ref) public returns(bool){
        require(isregister[ref],"ref is not register ");
        require(!isregister[_user],"address is register");
        user[_user].reff = ref;
        user[_user].positionsetting = "A";
        string memory a = user[ref].positionsetting;
        string memory bb;
        if (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked("R"))){
            user[_user].position = "R";
            bb = "R";
        }
        else if (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked("L"))){
            user[_user].position = "L";
            bb = "L";
        }
        else {
            user[_user].position = "L";
            bb = "L";
        }

        emit registeruser(_user,ref,address(0x0),bb);
        isregister[_user] = true;
        return true;
    }
    event mainlog(address sender,uint256 NoOfLand,uint256 _usdValue,uint256 BNBvalue,uint256 totalcount,uint256 Txfee);

    function Distribution(address _a,uint256 _u,uint256 _usdt,uint256 totalbuy,uint256 _txValue) public payable returns(bool){
        require(isregister[_a],"user not register");
        isbuy[_a] = true;
        uint256 refb;
        uint256 refusd;
        address ref;
        if (refferstop){
            ref = user[_a].reff;
            refb = _u * 10 /100;
            refusd = _usdt * 10 /100;
            //transfer amount
            if (ref != address(0x0)){
                payable(ref).transfer(refb);
            }

        }
        uint256 reward = _u * 10 /100;
        // reward transfer
        payable(RewardAddress).transfer(reward);

        uint256 remingamount =  _u * 40 /100;
        // transfer amount
        payable(developmentFund).transfer(remingamount);

        // remaing amount
        uint256 _A = _u - (refb + reward + remingamount);
        totalcount = totalcount + 1;
        amount[totalcount] = _A;
        isactivate[totalcount] = true;
        emit mainlog(_a,totalbuy,_usdt,_u,totalcount,_txValue);
        // emit Refferaddress(ref,refb,remingamount,refusd,totalcount);
        return true;
    }

    function BinaryDistribution(address[] memory addresslist,uint256[] memory _amount,uint256 _uq) public returns(bool){
        require(msg.sender == admin,"is not admin");
        require(addresslist.length == _amount.length,"not the same length of list");
        require(isactivate[_uq],"is not Exist");
        for(uint256 i=0;i<addresslist.length;i++){
            payable(addresslist[i]).transfer(_amount[i]);
        }
        isactivate[_uq] = false;
        return true;
    }
    function WithoutBinaryDistribution(uint256 _uq) public returns(bool){
        require(msg.sender == admin,"is not admin");
        require(isactivate[_uq],"is not Exist");
        payable(LeftOverBinary).transfer(amount[_uq]);
        isactivate[_uq] = false;
        return true;
    }

    function register(address[] memory _a,address[] memory _r,string[] memory _position,string[] memory _positionseting) public returns(bool){
        require(admin == msg.sender,"is not owner");
        require(_a.length == _r.length && _position.length == _positionseting.length,"is not same list");
        for(uint256 i=0;i<_a.length;i++){
            if(isregister[_r[i]] && !isregister[_a[i]]){
                user[_a[i]].reff = _r[i];
                user[_a[i]].positionsetting = _positionseting[i];
                user[_a[i]].position = _position[i];
                isregister[_a[i]] = true;
                emit registeruser(_a[i],_r[i],address(0x0),_position[i]);
            }
        }
        return true;
    }
    function changeAdmin(address _a) public returns(bool){
        require(owner == msg.sender,"is not owner");
        admin = _a;
        return true;
    }
}