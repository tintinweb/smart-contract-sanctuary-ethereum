// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../Ownable.sol";

contract ibgPresale is Ownable {

    IERC20 public ibgToken = IERC20(0xF16CD087e1C2C747b2bDF6f9A5498AA400D99C24);
    bool public openStaked = false;        
    bool public openRedeemed = false;      
    uint256 public redeemedFee = 90;      

    struct StakedInfo {
        address _address;   
        uint8 _type;        
        uint8 _combo;       
        uint256 _number;    
        uint256 _time;      
        uint256 _serialNumber;      
        uint256 _myorderNumber;     
    }

    struct UserInfo {
        address _parentAddress;
        uint256 _ordersNumber;  
        uint256 _stakedNumber;  
        uint256 _level;         
        bool _vip;              
    }

    mapping (address => mapping (uint256 => StakedInfo)) public myorders;     
    mapping (address => uint256) public recommends;      
    mapping (address => UserInfo) public userInfos;     
    mapping (uint8 => uint256) public comboMap;         
    uint256 public stakedNum = 0;   
    mapping (uint256 => StakedInfo) public orders;
    uint256 public discount;

    function setDiscount (uint256 _discount) public onlyOwner {
        discount = _discount;
    }

    
    function setVip (address _vipAddress, bool _true) public onlyOwner {
        UserInfo memory userinfo = userInfos[_vipAddress];
        userinfo._vip = _true;
        userInfos[_vipAddress] = userinfo;
    }

    
    event SetViplist(address indexed user, address[] _account, bool _bool);
    function setViplist(address[] memory _vipAddress, bool _bool) public onlyOwner {
        for (uint256 i = 0; i < _vipAddress.length; i++) {
            address _address = _vipAddress[i];
            UserInfo memory userinfo = userInfos[_address];
            userinfo._vip = _bool;
            userInfos[_address] = userinfo;
        }

        emit SetViplist(msg.sender, _vipAddress, _bool);
    }

    
    function staked(uint8  _combo, address _parent) public {
        uint256 amount = (comboMap[_combo] * discount)/100;
        UserInfo memory userinfo = userInfos[msg.sender];
        require((amount != 0 && openStaked) || userinfo._vip, "staked: error1");
        require(userinfo._stakedNumber == 0 || _combo > userinfo._level, "staked: error2");
        
        require(address(msg.sender) != _parent, "Participate: The recommender cannot be yourself");
        if (recommends[msg.sender] == 0 && _parent != address(0x0000000000000000000000000000000000000000) && userinfo._parentAddress == address(0x0000000000000000000000000000000000000000)) {
            userinfo._parentAddress = _parent;  
            recommends[_parent] += 1;
        }

        uint256 _transfer = amount - userinfo._stakedNumber;    

        userinfo._level = _combo;       
        userinfo._ordersNumber = 1;     
        userinfo._stakedNumber = amount; 
        ibgToken.transferFrom(msg.sender, address(this), _transfer);

        StakedInfo memory info = myorders[msg.sender][userinfo._ordersNumber];
        if (info._serialNumber == 0) {
            info._address = msg.sender;
            info._combo = _combo;
            info._number = amount;
            info._type = 1;
            info._serialNumber = stakedNum;
            info._time = block.timestamp;
            info._myorderNumber = userinfo._ordersNumber;

            myorders[msg.sender][userinfo._ordersNumber] = info;    
            orders[stakedNum] = info;                               
            stakedNum += 1;
        } else {

            info._combo = _combo;
            info._number = amount;
            info._type = 1;
            info._time = block.timestamp;

            myorders[msg.sender][userinfo._ordersNumber] = info;    
            orders[info._serialNumber] = info;                      
        }
        
        userInfos[msg.sender] = userinfo;
        
    }

    
    function redeemed(uint256 _serialNumber) public {
        StakedInfo memory info = orders[_serialNumber];     
        UserInfo memory userinfo = userInfos[msg.sender];
        uint256 amount = info._number;
        require(openRedeemed && info._type == 1 && info._address == msg.sender, "redeemed: error");
        ibgToken.transfer(msg.sender, (amount * redeemedFee)/100);
        
        info._type = 2;
        info._time = block.timestamp;
        orders[_serialNumber] = info;                        
        myorders[msg.sender][info._myorderNumber] = info;    
        userinfo._stakedNumber = 0;                          
        userinfo._level = 0;
        userInfos[msg.sender] = userinfo;
    }

    function setCombo(uint8 _combo, uint256 _amount, uint8 _decimals) public onlyOwner {
        comboMap[_combo] = _amount * 10**_decimals;
    }

    event SetCombolist(address indexed user, uint8[] _combo, uint256[] _amount);
    function setCombolist(uint8[] memory _combo, uint256[] memory _amount) public onlyOwner {
        for (uint256 i = 0; i < _combo.length; i++) {
            uint8 key = _combo[i];
            comboMap[key] = _amount[i] * 10**18;
        }

        emit SetCombolist(msg.sender, _combo, _amount);
    }

    function setOpenStaked(bool _open) public onlyOwner {
        openStaked = _open;
    }
    function setOpenRedeemed(bool _open) public onlyOwner {
        openRedeemed = _open;
    }
    function destoryContract () public onlyOwner {
        ibgToken.transfer(msg.sender, ibgToken.balanceOf(address(this)));
    }
    function setRedeemedFee (uint256 _redeemedFee) public onlyOwner {
        redeemedFee = _redeemedFee;
    }
    function setIBGToken (IERC20 _ibgToken) public onlyOwner {
        ibgToken = _ibgToken;
    }
}