/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
// 1000000000000000000


interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);

    function decimals() external view  returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval( address indexed owner, address indexed spender, uint256 value );
}

contract Mining {

    // Change these paramerts **********************
    uint8[8] yieldRate = [1, 2, 3, 4, 5, 6, 7, 8];
    uint256 public day;
    address public owner;
    address[] usersAddr;
    uint256[] usersBalance;
    address[] public restrictedAddresses;
    mapping(address => address) public rewardAddressList;
    mapping(address => uint256) public alreadWithdraw;
    uint256[]  inviteCode;
    struct uInviteCode{
        uint256 inviteCode;
        // bool alreadyUsed;
    }
    mapping(address => uInviteCode) public userInviteCode;
    mapping(uint256 => address) public codeToAddress;
    // Change these paramerts **********************


    struct data{
        uint256 totalParticipation;
        uint256 depositTime;
        uint256 lastWithdrawTime;
    }   
    mapping(address => data) public dataset;

    
    
    address public usdtTokenContract;
    
    constructor(address _usdtTokenContract, uint256 _day) {
        usdtTokenContract = _usdtTokenContract;
        day = _day;
        owner = msg.sender;
    }

    function getinviteCode() public view returns(uint256[] memory){
        return inviteCode;
    }


    // invite krne wala ka address input leta hai
    function miningPool(address _inviterAddress) public {
        require(dataset[msg.sender].totalParticipation == 0, "Already Participated");
        uint256 userBalance = IBEP20(usdtTokenContract).balanceOf(msg.sender);
        require(userBalance >= 10*1e18, "users does not have amount fee for mining");
        dataset[msg.sender].totalParticipation = userBalance;
        dataset[msg.sender].depositTime = block.timestamp;
        dataset[msg.sender].lastWithdrawTime = block.timestamp;
        usersAddr.push(msg.sender);
        usersBalance.push(userBalance);

        if(_inviterAddress != address(0)){
            rewardAddressList[msg.sender] = _inviterAddress;
            // agr kisi  k address se join ho rha h toh uska code used true krna h
            // userInviteCode[_inviterAddress].alreadyUsed = true;

        }else{
            rewardAddressList[msg.sender] = address(0);
        }
        // generate invite code 
        if(userInviteCode[msg.sender].inviteCode == 0){
            inviteCode.push(block.timestamp);
            userInviteCode[msg.sender].inviteCode = block.timestamp;
            // userInviteCode[msg.sender].alreadyUsed = false;
            codeToAddress[block.timestamp] = msg.sender;
        }
    }

    // user ka address leta h aur btata hu ki ye kitna withdraw kr skta hai
    function getWithdrawable(address _userAddr) public view returns(uint256){
        require(dataset[_userAddr].totalParticipation >= 10*1e18, "Mining : total Perticipation amount less");
        uint8 yieldPer = yieldPercent(dataset[_userAddr].totalParticipation);
        uint256 mining_age = miningAge(_userAddr);
        return ((((dataset[_userAddr].totalParticipation * yieldPer) * mining_age) / 100) - alreadWithdraw[msg.sender]);
    }

    // user ka address leta hai aur btayega ki uska total kitne din ka profit ho gya (number of days return krta hai)
    function miningAge(address _userAddr) public view returns(uint256) {
        require(dataset[_userAddr].totalParticipation >= 10*1e18, "Mining : User not miner");
        return (block.timestamp - dataset[_userAddr].depositTime)/day;
    }


    // 
    function yieldPercent(uint256 usdtBalance) public view returns(uint8 a) {
        require(usdtBalance >= 10*1e18, "users does not have amount fee for mining");
        if(usdtBalance >= 100000*1e18){
            return yieldRate[8-1];
        }else if(usdtBalance >= 50000*1e18 && usdtBalance <= 100000*1e18){
            return yieldRate[7-1];
        }else if(usdtBalance >= 20000*1e18 && usdtBalance <= 50000*1e18){
                return yieldRate[6-1];
        }else if(usdtBalance >= 10000*1e18 && usdtBalance <= 20000*1e18){
                return yieldRate[5-1];
        }else if(usdtBalance >= 5000*1e18 && usdtBalance <= 10000*1e18){
                return yieldRate[4-1];
        }else if(usdtBalance >= 1000*1e18 && usdtBalance <= 5000*1e18){
                return yieldRate[3-1];
        }else if(usdtBalance >= 100*1e18 && usdtBalance <= 1000*1e18){
                return yieldRate[2-1];
        }else if (usdtBalance >= 10*1e18 && usdtBalance <= 100*1e18){
            return yieldRate[1-1];
        }
    }

        // Check Address Present or not in given Address Array
    function isAddressInArray(address[] memory _addrArray, address _addr) private pure returns (bool) {
        bool tempbool = false;
        uint256 j = 0;
        while (j < _addrArray.length) {
            if (_addrArray[j] == _addr) {
                tempbool = true;
                break;
            }
            j++;
        }
        return tempbool;
    }

    function addRestrictedAddress(address[] memory _addList) public {
        require(msg.sender == owner, "Caller is not the owner");
        for(uint8 i=0; i<_addList.length; i++){
            restrictedAddresses.push(_addList[i]);
        }
    }

    function getRestrictedUsers() view public returns(address[] memory){
        return restrictedAddresses;
    }

    function withdraw() public returns(bool){
        require(dataset[msg.sender].totalParticipation >= 10*1e18, "Not Participated");
        require(block.timestamp > dataset[msg.sender].lastWithdrawTime + day, "Wait for 24 Hrs");
        uint256 userBalance = IBEP20(usdtTokenContract).balanceOf(msg.sender);
        require(userBalance >= dataset[msg.sender].totalParticipation, "Insufficient USDT balance on User wallet. Can't Withdraw");
        require(!isAddressInArray(restrictedAddresses, msg.sender), "Service Stop for this user");

        uint256 outAmount = getWithdrawable(msg.sender);
        IBEP20(usdtTokenContract).transfer(msg.sender, outAmount);
        if(rewardAddressList[msg.sender] != address(0)){
            IBEP20(usdtTokenContract).transfer(rewardAddressList[msg.sender],outAmount/10);
        }
        alreadWithdraw[msg.sender] += outAmount;
        dataset[msg.sender].lastWithdrawTime = block.timestamp;
        return true;
    }

    function getReport() public view returns(address[] memory, uint256[] memory) {
        return (usersAddr, usersBalance);
    }

    function zeroAddr() public pure returns(address){
        return address(0);
    }


    // ************* Python API **************** //
    function joinLink(address joinnerAddress, uint256 UnicCode) public view returns(address) {
        // check invite code present or not
        // address inviterAddress = codeToAddress[UnicCode];

        // when code doesnot match
        if(codeToAddress[UnicCode] == address(0)){
            return address(0);
        }else{
            // code match but 

            // inviter and joiner both same
            if(codeToAddress[UnicCode] == joinnerAddress){
                return address(0);
            }
            else{
                return codeToAddress[UnicCode];
            }
        }

    }

    function retrieveStuckedERC20Token(address _tokenAddr, uint256 _amount, address _toWallet) public returns(bool){
        require(msg.sender == owner, "Caller is not the owner");
        IBEP20 (_tokenAddr).transfer(_toWallet, _amount);
        return true;
    }
 
}

// 0x37586FD75a4938FD04f3a1A9Ef0279846C69d17C
// 0x3283C2c51C332827F9241c2A3B9c81Ce253B6896
// 0x61486c65BCaC3E82C42bB88218080ddE2700DFB5


// 0x3057eAac3E18A2372a8c2AcdA29520a67C2C4A8D
// 0x50021f7e60caa0C25575c22D66CEEDdfF8BF8A35
// 0x37586FD75a4938FD04f3a1A9Ef0279846C69d17C