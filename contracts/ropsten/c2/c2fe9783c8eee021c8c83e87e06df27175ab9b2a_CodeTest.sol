// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract CodeTest is ERC20, ERC20Burnable, Ownable{
    
	address payable public team_wallet_1;
    address payable public team_wallet_2;

    struct UserStruct {
        uint id;
        address payable referrerID;
        address[] referral;
        uint investment;
        uint max_investment;
		uint investment_time;
		uint ROI_percent;
		uint ROI_before_investment;
		uint ROI_taken_time;
        uint withdrawal_time;
        uint[3][3] ROI;
        uint level;
    }

    uint public totalInvest = 0;
    uint public withdrawal = 0;
	uint public withdrawal_fee_in_lock = 5;
	uint public withdrawal_fee_after_lock = 1;
	uint public lock_period = 0 days;
	uint public token_price = 1 ether;
	uint public BNB_price = 1 ether;

    uint[] public reward_precent = [100,100,10,10,10,10,10,10,10,10,10];
	uint[] public min_balance = [0.1 ether, 5 ether, 10 ether];
	uint[] public ROI_percent = [25, 30, 35];
    uint[] public level = [3, 6, 9, 12, 15];

    mapping (address => UserStruct) public users;

    uint public currUserID = 0;

    event regEvent(address indexed _user, address indexed _referrer, uint _time);
    event investEvent(address indexed _user, uint _amount, uint _time);
    event getMoneyEvent(uint indexed _user, uint indexed _referral, uint _amount, uint _level, uint _time);
	event WithdrawalEvent(address indexed _user, uint _amount, uint _time);
	event ROI_WithdrawalEvent(address indexed _user, uint _amount, uint _time);

    constructor() ERC20("Yoplex", "Yoplex") {
		team_wallet_1 = payable(msg.sender);
        team_wallet_2 = payable(msg.sender);

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            id: currUserID,
            referrerID: payable(address(0)),
            referral: new address[](0),
            investment: 99999999 ether,
            max_investment: 99999999 ether,
			investment_time: block.timestamp,
			ROI_percent: 2,
			ROI_before_investment: 0,
			ROI_taken_time: block.timestamp,
            withdrawal_time: block.timestamp,
            ROI: [[uint(0),uint(0),uint(0)],[uint(0),uint(0),uint(0)],[uint(0),uint(0),uint(0)]],
            level: 0
        });
        users[msg.sender] = userStruct;
    }

	function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function regUser(address payable _referrerID) public payable {
        require(users[msg.sender].id == 0, "User exist");
        require(msg.value >= min_balance[0], "register with minimum 1 ETH");
        if(_referrerID == address(0)){
            _referrerID = payable(owner());
        }

        totalInvest += msg.value;
        currUserID++;

		UserStruct memory userStruct;
        userStruct = UserStruct({
            id: currUserID,
            referrerID: _referrerID,
            referral: new address[](0),
            investment: BNB_to_USD(msg.value),
            max_investment: BNB_to_USD(msg.value),
			investment_time: block.timestamp,
			ROI_percent: 0,
			ROI_before_investment: 0,
			ROI_taken_time: block.timestamp,
            withdrawal_time: block.timestamp,
            ROI: [[BNB_to_USD(msg.value),uint(0),uint(0)],[uint(0),uint(0),uint(0)],[uint(0),uint(0),uint(0)]],
            level: 0
        });
        users[msg.sender] = userStruct;
        users[_referrerID].referral.push(msg.sender);
		for (uint i = 0; i < min_balance.length; i++) {
			if(users[msg.sender].investment >= min_balance[i]){
				users[msg.sender].ROI_percent = i;
			}
		}
		team_wallet_1.transfer(msg.value * 4 / 10); // 40%
        team_wallet_2.transfer(msg.value / 10); // 10%
        emit regEvent(msg.sender, _referrerID, block.timestamp);
    }

    function invest() public payable {
        require(users[msg.sender].id > 0, "User not exist");
        require(msg.value > 0, "invest with ETH");

        totalInvest += msg.value;

        users[msg.sender].ROI_before_investment += viewUserROI(msg.sender);
		users[msg.sender].ROI_taken_time = block.timestamp;
        users[msg.sender].investment_time = block.timestamp;
        uint before_investment_amt = users[msg.sender].investment;
        uint before_investment_per = users[msg.sender].ROI_percent;
        users[msg.sender].investment += BNB_to_USD(msg.value);
        for (uint i = 0; i < min_balance.length; i++) {
			if(users[msg.sender].investment >= min_balance[i]){
				users[msg.sender].ROI_percent = i;
			}
		}
        uint after_investment_amt = users[msg.sender].investment;
        uint after_investment_per = users[msg.sender].ROI_percent;

        giveROI(msg.sender, after_investment_amt, before_investment_amt, after_investment_per, before_investment_per, 0, 0);

        if(users[msg.sender].investment > users[msg.sender].max_investment){
            users[msg.sender].max_investment = users[msg.sender].investment;
        }

        emit investEvent(msg.sender, msg.value, block.timestamp);
    }

    function giveROI(address _user, uint _amountAdd, uint _amountSub, uint _roiAdd, uint _roiSub, uint _gen, uint _dl_amount) internal {
        if(_gen < 21 && _user != address(0)){
            if(_gen < 2){
                users[_user].ROI[_roiAdd][0] += _amountAdd;
                users[_user].ROI[_roiSub][0] -= _amountSub;
            }else if(_gen < 11){
                users[_user].ROI[_roiAdd][1] += _amountAdd;
                users[_user].ROI[_roiSub][1] -= _amountSub;
            }else{
                users[_user].ROI[_roiAdd][2] += _amountAdd;
                users[_user].ROI[_roiSub][2] -= _amountSub;
            }
            if(_gen > 11){
                _dl_amount += users[_user].investment;
            }
            if(users[_user].investment >= 3000 && _dl_amount >= 200000){
                users[_user].level = 1;
            }
            giveROI(users[_user].referrerID, _amountAdd, _amountSub, _roiAdd, _roiSub, _gen, _dl_amount);
        }
    }

    function viewUserROI(address _user) public view returns(uint) {
        uint ROI = 0;
        for (uint i = 0; i < 3; i++) {
            ROI += users[_user].ROI[i][0] * ROI_percent[i] * ((block.timestamp - users[_user].ROI_taken_time) / 10 minutes) / 10000;
            if(users[_user].referral.length >= 5){
                ROI += users[_user].ROI[i][1] * ROI_percent[i] * ((block.timestamp - users[_user].ROI_taken_time) / 10 minutes) / 10000 / 10;
            }
            if(users[_user].level > 0){
                ROI += users[_user].ROI[i][2] * ROI_percent[i] * ((block.timestamp - users[_user].ROI_taken_time) / 10 minutes) / 10000 * level[users[_user].level] / 100;
            }
        }
        return ROI;
    }

	function USD_to_token(uint _amount) public view returns(uint) {
        return _amount / token_price;
    }

	function BNB_to_USD(uint _amount) public view returns(uint) {
        return _amount * BNB_price;
    }

	function USD_to_BNB(uint _amount) public view returns(uint) {
        return _amount / BNB_price;
    }

	function viewUserGen(address _user, uint _gen) public view returns(uint) {
        uint gen = _gen;
        for (uint i = 0; i < users[_user].referral.length; i++) {
            uint temp = viewUserGen(users[_user].referral[i], (_gen + uint(1)));
            if(temp > gen){
                gen = temp;
            }
        }
        return gen;
    }

    function viewUserReferral(address _user) public view returns(address[] memory) {
        return users[_user].referral;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function ROI_Withdrawal() public returns (bool) {
		require(users[msg.sender].id > 0, "User not exist");
        uint amount = viewUserROI(msg.sender);
        amount += users[msg.sender].ROI_before_investment;
		users[msg.sender].ROI_taken_time = block.timestamp;
        users[msg.sender].ROI_before_investment = 0;
		payable(msg.sender).transfer(USD_to_BNB(amount));
		emit ROI_WithdrawalEvent(msg.sender, amount, block.timestamp);
        return true;
    }

	function userWithdrawal() public returns (bool) {
		require(users[msg.sender].id > 0, "User not exist");
		require(users[msg.sender].investment_time + lock_period < block.timestamp, "Token is in lock period");
        uint amount = 0;
		if(((block.timestamp - users[msg.sender].withdrawal_time) / 10 minutes) >= 5){
			amount = users[msg.sender].investment;
		}else{
			amount = users[msg.sender].max_investment * (20 * ((block.timestamp - users[msg.sender].withdrawal_time) / 10 minutes)) / 100;
		}
        if(amount > users[msg.sender].investment){
            amount = users[msg.sender].investment;
        }
        
        uint before_investment_amt = users[msg.sender].investment;
        uint before_investment_per = users[msg.sender].ROI_percent;
        
		users[msg.sender].investment -= amount;

        for (uint i = 0; i < min_balance.length; i++) {
			if(users[msg.sender].investment >= min_balance[i]){
				users[msg.sender].ROI_percent = i;
			}
		}
        uint after_investment_amt = users[msg.sender].investment;
        uint after_investment_per = users[msg.sender].ROI_percent;

        giveROI(msg.sender, after_investment_amt, before_investment_amt, after_investment_per, before_investment_per, 0, 0);

        users[msg.sender].withdrawal_time = block.timestamp;
        users[msg.sender].ROI_before_investment += viewUserROI(msg.sender);
        users[msg.sender].ROI_taken_time = block.timestamp;

		_mint(msg.sender, USD_to_token(amount));
		emit WithdrawalEvent(msg.sender, amount, block.timestamp);
        return true;
    }

	function beneficiaryWithdrawal(address payable _address, uint _amount) public onlyOwner returns (bool) {
        require(_address != address(0), "Enter right adress");
        require(_amount < address(this).balance && _amount > 0, "Enter right amount");
        withdrawal += _amount;
        _address.transfer(_amount);
        return true;
    }

    function updateRewardPercent(uint[] memory _precent_of_reward) onlyOwner public returns (bool) {
        reward_precent = _precent_of_reward;
        return true;
    }

	function update_withdrawal_fee_in_lock(uint _withdrawal_fee_in_lock) onlyOwner public returns (bool) {
        withdrawal_fee_in_lock = _withdrawal_fee_in_lock;
        return true;
    }

	function update_withdrawal_fee_after_lock(uint _withdrawal_fee_after_lock) onlyOwner public returns (bool) {
        withdrawal_fee_after_lock = _withdrawal_fee_after_lock;
        return true;
    }

	function update_lock_period(uint _lock_period) onlyOwner public returns (bool) {
        lock_period = _lock_period;
        return true;
    }

	function update_reward_precent(uint[] memory _reward_precent) onlyOwner public returns (bool) {
        reward_precent = _reward_precent;
        return true;
    }

	function update_min_balance(uint[] memory _min_balance) onlyOwner public returns (bool) {
        min_balance = _min_balance;
        return true;
    }

	function update_ROI_percente(uint[] memory _ROI_percent) onlyOwner public returns (bool) {
        ROI_percent = _ROI_percent;
        return true;
    }

    function update_team(address payable _address_1, address payable _address_2) onlyOwner public returns (bool) {
        team_wallet_1 = _address_1;
        team_wallet_2 = _address_2;
        return true;
    }
}