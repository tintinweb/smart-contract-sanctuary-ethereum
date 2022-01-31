// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BRC20.sol";
import "./BRC20Burnable.sol";
import "./Ownable.sol";
import "./ChainlinkClient.sol";
import "./AggregatorV3Interface.sol";

contract Yoplex is BRC20, BRC20Burnable, Ownable, ChainlinkClient{
	using Chainlink for Chainlink.Request;
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    AggregatorV3Interface internal priceFeed;
    
	address[] public team_wallet;
	uint[] public team_percent;
    
    struct UserStruct {
        uint id;
        address[] referral;
        uint[] investment_amount;
		uint[] investment_time;
		uint ROI_taken;
		uint ROI_taken_time;
		uint[] withdrawal_amount;
        uint[] withdrawal_time;
    }

    uint public totalInvest = 0;
	uint public lock_period = 5 minutes;
	uint public token_price = 100000000;
    bool public livePrice = false;

	uint public min_balance = 10;

    mapping (address => UserStruct) public users;
	mapping (uint => address) public ID_to_address;
	mapping (bytes32 => address) public withdrawal_request;
    mapping (bytes32 => uint) public withdrawal_amount;

    uint public currUserID = 0;
    string public baseURL;

    event regEvent(address indexed _user, address indexed _referrer, uint _time);
    event investEvent(address indexed _user, uint _amount, uint _time);
	event WithdrawalEvent(address indexed _user, uint _amount, uint _time);
	event ROI_WithdrawalEvent(address indexed _user, uint _amount, uint _time);

    constructor() BRC20("Yoplex", "YPLX") {
		setChainlinkToken(0xa36085F69e2889c224210F603D836748e7dC0088);
        // oracle = 0x46cC5EbBe7DA04b45C0e40c061eD2beD20ca7755;
        // jobId = "60803b12c6de4443a99a6078aa59ef79";
        oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
        jobId = "d5270d1c311941d0b08bead21fea7747";
        fee = 0.1 * 10 ** 18; // (Varies by network and job)

        priceFeed = AggregatorV3Interface(0x8993ED705cdf5e84D0a3B754b5Ee0e1783fcdF16);
    }

	

	function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function regUser(address payable _referrerID) public payable {
        require(users[msg.sender].id == 0, "User exist");
        require(BNB_to_USD(msg.value) >= min_balance, "Amount is less then minimum amount");

        currUserID++;

		UserStruct memory userStruct;
        userStruct = UserStruct({
            id: currUserID,
            referral: new address[](0),
            investment_amount: new uint[](0),
            investment_time: new uint[](0),
			ROI_taken: 0,
			ROI_taken_time: block.timestamp,
			withdrawal_amount: new uint[](0),
			withdrawal_time: new uint[](0)
        });
        users[msg.sender] = userStruct;
		ID_to_address[currUserID] = msg.sender;
		if(users[_referrerID].id != 0){
            users[_referrerID].referral.push(msg.sender);
        }
		
		emit regEvent(msg.sender, _referrerID, block.timestamp);
		invest();
    }

    function invest() public payable {
        require(users[msg.sender].id > 0, "User not exist");
        require(msg.value > 0, "invest with ETH");

        totalInvest += msg.value;
		users[msg.sender].investment_amount.push(BNB_to_USD(msg.value));
        users[msg.sender].investment_time.push(block.timestamp);
		
		for (uint i = 0; i < team_wallet.length; i++) {
			payable(team_wallet[i]).transfer(msg.value * team_percent[i] / 100);
		}
        emit investEvent(msg.sender, msg.value, block.timestamp);
    }

	function ROI_Withdrawal() public returns (bool) {
		require(users[msg.sender].id > 0, "User not exist");
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        request.add("get", string(abi.encodePacked(baseURL, "roi/?address=0x", toAsciiString(msg.sender))));
        request.add("path", "data");
        withdrawal_request[sendChainlinkRequestTo(oracle, request, fee)] = msg.sender;
        return true;
    }

	function fulfill(bytes32 _requestId, uint256 _volume) public recordChainlinkFulfillment(_requestId){
		address payable _user = payable(withdrawal_request[_requestId]);
        uint amount = USD_to_BNB(_volume);
		users[_user].ROI_taken += amount;
        users[_user].ROI_taken_time = block.timestamp;
		_user.transfer(amount);
		emit ROI_WithdrawalEvent(_user, amount, block.timestamp);
    }

	function userWithdrawal() public returns (bool) {
        require(users[msg.sender].id > 0, "User not exist");
        uint amount = 0;
        for (uint i = 0; i < users[msg.sender].investment_time.length; i++) {
            if(( ((block.timestamp - lock_period - users[msg.sender].investment_time[i]) / 10 minutes)) >= 5){
                amount += users[msg.sender].investment_amount[i];
            }else{
                amount += users[msg.sender].investment_amount[i] * (20 * ((block.timestamp - lock_period - users[msg.sender].investment_time[i]) / 10 minutes)) / 100;
            }
        }
        uint amount_withdrawal = 0;
        for (uint i = 0; i < users[msg.sender].withdrawal_amount.length; i++) {
            amount_withdrawal += users[msg.sender].withdrawal_amount[i];
        }
        amount -= amount_withdrawal;
        if(livePrice){       
            Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill1.selector);
            string memory url = "tokenPrice";      
            string memory URLs = string(abi.encodePacked(baseURL,url));
            request.add("get", URLs);
            request.add("path", "data");
            bytes32 request_id = sendChainlinkRequestTo(oracle, request, fee);
            withdrawal_request[request_id] = msg.sender;
            withdrawal_amount[request_id] = amount;
        }else{
			users[msg.sender].withdrawal_amount.push(amount);
			users[msg.sender].withdrawal_time.push(block.timestamp);

			_mint(msg.sender, USD_to_token(amount));
			emit WithdrawalEvent(msg.sender, amount, block.timestamp);
        }
        return true;
    }

    function fulfill1(bytes32 _requestId, uint256 _volume) public recordChainlinkFulfillment(_requestId){
		address payable _user = payable(withdrawal_request[_requestId]);
        uint amount = withdrawal_amount[_requestId];
        token_price = _volume;

		users[_user].withdrawal_amount.push(amount);
		users[_user].withdrawal_time.push(block.timestamp);

        _mint(msg.sender, USD_to_token(amount));
        emit WithdrawalEvent(_user, amount, block.timestamp);
    }

	function beneficiaryWithdrawal(address payable _address, uint _amount) public onlyOwner returns (bool) {
        require(_address != address(0), "Enter right adress");
        require(_amount < address(this).balance && _amount > 0, "Enter right amount");
        _address.transfer(_amount);
        return true;
    }

	function USD_to_token(uint _amount) public view returns(uint) {
        return _amount * 10**18 / token_price;
    }

	function BNB_to_USD(uint _amount) public view returns(uint) {
		(, int price,,,) = priceFeed.latestRoundData();
        return (_amount * uint(price)) /10**18;
    }

	function USD_to_BNB(uint _amount) public view returns(uint) {
		(, int price,,,) = priceFeed.latestRoundData();
        return _amount * 10**18 / uint(price);
    }

    function viewUserReferral(address _user) public view returns(address[] memory) {
        return users[_user].referral;
    }

	function viewUserInvestment_time(address _user) public view returns(uint[] memory) {
        return users[_user].investment_time;
    }

	function viewUserInvestment_amount(address _user) public view returns(uint[] memory) {
        return users[_user].investment_amount;
    }

	function viewUserWithdrawal_amount(address _user) public view returns(uint[] memory) {
        return users[_user].withdrawal_amount;
    }

	function viewUserWithdrawal_time(address _user) public view returns(uint[] memory) {
        return users[_user].withdrawal_time;
    }

	function update_lock_period(uint _lock_period) onlyOwner public returns (bool) {
        lock_period = _lock_period;
        return true;
    }

	function update_min_balance(uint _min_balance) onlyOwner public returns (bool) {
        min_balance = _min_balance;
        return true;
    }

    function update_team(address[] memory _address, uint[] memory _percent) onlyOwner public returns (bool) {
        team_wallet = _address;
        team_percent = _percent;
        return true;
    }

	function setBaseURL(string memory url) public onlyOwner {
        baseURL = url;
    }

	

	function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

}