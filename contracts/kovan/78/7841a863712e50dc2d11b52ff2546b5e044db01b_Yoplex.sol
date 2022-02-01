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
    
	address[] private team_wallet;
	uint[] private team_percent;
    
    struct InvestStruct {
        uint id;
		uint time;
		uint amount_USD;
        uint amount_BNB;
        uint amount_YPLX;
        uint YPLX_USD;
    }

    struct WithdrawalStruct {
        uint id;
		uint time;
		uint amount_USD;
        uint amount_YPLX;
    }

    struct UserStruct {
        uint id;
        address[] referral;     		
		uint ROI_taken_USD;
        uint ROI_taken_BNB;
		uint ROI_taken_time;
    }

    uint private total_invest = 0;
	uint private lock_period = 5 minutes;
	uint private token_price = 100000000; // 1 USD  = 1 YPLX
    bool private live_price = false;

	uint private min_balance = 1; // 1 USD

    mapping (address => UserStruct) private users;
    mapping (address => InvestStruct[]) private investment;
    mapping (address => WithdrawalStruct[]) private withdawal;
	mapping (uint => address) private ID_to_address;
	mapping (bytes32 => address) private investment_request;
    mapping (bytes32 => address) private ROI_request;
    mapping (bytes32 => uint) private investment_index;
    

    uint private curr_userID = 0;
    uint private investmentID = 0;
    uint private withdrawalID = 0;
    string private base_URL;

    event regEvent(address indexed _user, address indexed _referrer, uint _time);
    event investEvent(address indexed _user, uint _amountInBNB, uint _amountInUSD, uint _time);
	event WithdrawalEvent(address indexed _user, uint _amountInUSD, uint _amountInYPLX, uint _time);
	event ROI_WithdrawalEvent(address indexed _user, uint _amountInBNB, uint _amountInUSD, uint _time);

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
        curr_userID++;      
		UserStruct memory userStruct;
        userStruct = UserStruct({
            id: curr_userID,
            referral: new address[](0),         
            ROI_taken_USD: 0,
			ROI_taken_BNB: 0,
			ROI_taken_time: block.timestamp
        });
        if(users[_referrerID].id != 0){
            users[_referrerID].referral.push(msg.sender);
        }
        users[msg.sender] = userStruct;
		ID_to_address[curr_userID] = msg.sender;
	
		emit regEvent(msg.sender, _referrerID, block.timestamp);
		invest();
    }

    function invest() public payable {
        require(users[msg.sender].id > 0, "User not exist");
        require(msg.value > 0, "invest with ETH");
        investmentID++;
        InvestStruct memory investStruct;
        investStruct = InvestStruct({
            id: investmentID,
            time: block.timestamp,
            amount_USD: BNB_to_USD(msg.value),
            amount_BNB: msg.value,
            amount_YPLX: USD_to_token(BNB_to_USD(msg.value)),
            YPLX_USD: token_price
        });
        investment[msg.sender].push(investStruct);
        total_invest += msg.value;
		if(live_price){       
            Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill1.selector);
            string memory url = "tokenPrice";      
            string memory URLs = string(abi.encodePacked(base_URL,url));
            request.add("get", URLs);
            request.add("path", "data");
            bytes32 request_id = sendChainlinkRequestTo(oracle, request, fee);
            investment_request[request_id] = msg.sender;
            investment_index[request_id] = investment[msg.sender].length - 1;
        }
		for (uint i = 0; i < team_wallet.length; i++) {
			payable(team_wallet[i]).transfer(msg.value * team_percent[i] / 100);
		}
        emit investEvent(msg.sender, msg.value, BNB_to_USD(msg.value), block.timestamp);
    }

    function fulfill1(bytes32 _requestId, uint256 _volume) public recordChainlinkFulfillment(_requestId){
		address _user = investment_request[_requestId];       
        uint index = investment_index[_requestId];
        token_price = _volume;
        investment[_user][index].amount_YPLX = USD_to_token(investment[_user][index].amount_USD);
        investment[_user][index].YPLX_USD = token_price;
    }

	function ROI_Withdrawal() public returns (bool) {
		require(users[msg.sender].id > 0, "User not exist");
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        request.add("get", string(abi.encodePacked(base_URL, "roi/?address=0x", toAsciiString(msg.sender))));
        request.add("path", "data");
        ROI_request[sendChainlinkRequestTo(oracle, request, fee)] = msg.sender;
        return true;
    }

	function fulfill(bytes32 _requestId, uint256 _volume) public recordChainlinkFulfillment(_requestId){
		address payable _user = payable(ROI_request[_requestId]);
        uint amount = USD_to_BNB(_volume);
		users[_user].ROI_taken_BNB += amount;
        users[_user].ROI_taken_USD += _volume;
        users[_user].ROI_taken_time = block.timestamp;
		_user.transfer(amount);
		emit ROI_WithdrawalEvent(_user, amount, _volume, block.timestamp);
    }

	function YPLX_Withdrawal() public returns (bool) {
        require(users[msg.sender].id > 0, "User not exist");
        uint investment_amount_USD = 0;
        uint investment_amount_YPLX = 0;
        for (uint i = 0; i < investment[msg.sender].length; i++) {
            uint diff = ( ((block.timestamp - lock_period - investment[msg.sender][i].time) / 10 minutes));
            if(diff >= 5){
                investment_amount_USD += investment[msg.sender][i].amount_USD;
                investment_amount_YPLX += investment[msg.sender][i].amount_YPLX;
            }else{
                investment_amount_USD += (investment[msg.sender][i].amount_USD * 20 * diff) / 100;
                investment_amount_YPLX += (investment[msg.sender][i].amount_YPLX * 20 * diff) / 100;          
            }
        }
        uint amount_withdrawal_USD = 0;
        uint amount_withdrawal_YPLX = 0;
        for (uint i = 0; i < withdawal[msg.sender].length; i++) {
            amount_withdrawal_USD += withdawal[msg.sender][i].amount_USD;
            amount_withdrawal_YPLX += withdawal[msg.sender][i].amount_YPLX;
        }
        investment_amount_USD -= amount_withdrawal_USD;
        investment_amount_YPLX -= amount_withdrawal_YPLX;
        withdrawalID++;
        WithdrawalStruct memory withdrawalStruct;
        withdrawalStruct = WithdrawalStruct({
            id: withdrawalID,
            time: block.timestamp,
            amount_USD: investment_amount_USD,
            amount_YPLX: investment_amount_YPLX         
        });

        withdawal[msg.sender].push(withdrawalStruct);
		
		_mint(msg.sender, investment_amount_YPLX);
		emit WithdrawalEvent(msg.sender, investment_amount_USD, investment_amount_YPLX, block.timestamp);
        return true;
    }   

	function beneficiaryWithdrawal(address payable _address, uint _amount) public onlyOwner returns (bool) {
        require(_address != address(0), "Enter right adress");
        require(_amount <= address(this).balance && _amount > 0, "Enter right amount");
        _address.transfer(_amount);
        return true;
    }

    function setTokenPrice(uint _price) public onlyOwner {
        token_price = _price;
    }

    function toggleLivePrice() public onlyOwner {
        live_price = !live_price;
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

    function BNB_Price() public view returns(uint) {
		(, int price,,,) = priceFeed.latestRoundData();
        return uint(price);
    }

    function YPLX_Price() public view returns(uint) {		
        return token_price;
    }

    function viewUserReferral(address _user) public view returns(address[] memory) {
        return users[_user].referral;
    }

	function viewUserDetails(address _user) public view returns(UserStruct memory) {
        return users[_user];
    }

	function updateLockPeriod(uint _lock_period) onlyOwner public returns (bool) {
        lock_period = _lock_period;
        return true;
    }

	function updateMinBalance(uint _min_balance) onlyOwner public returns (bool) {
        min_balance = _min_balance;
        return true;
    }

    function updateTeam(address[] memory _address, uint[] memory _percent) onlyOwner public returns (bool) {
        team_wallet = _address;
        team_percent = _percent;
        return true;
    }

	function setBaseURL(string memory url) public onlyOwner {
        base_URL = url;
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

    function teamWallet() public view returns(address[] memory){
        return team_wallet;
    }

    function teamPercent() public view returns(uint[] memory){
        return team_percent;
    }

    function totalInvest() public view returns(uint){
        return total_invest;
    }

    function lockPeriod() public view returns(uint){
        return lock_period;
    }

    function tokenPrice() public view returns(uint){
        return token_price;
    }

    function livePrice() public view returns(bool){
        return live_price;
    }

    function minBalance() public view returns(uint256){
        return min_balance;
    }

    function idToAddress(uint _id) public view returns(address){
        return ID_to_address[_id];
    }

    function baseURL() public view returns(string memory){
        return base_URL;
    }

    function currUserID() public view returns(uint){
        return curr_userID;
    }

    function investmentDetails(address _user, uint _index) public view returns(InvestStruct memory){
        return investment[_user][_index];
    }

    function withdrawalDetails(address _user, uint _index) public view returns(WithdrawalStruct memory){
        return withdawal[_user][_index];
    }

    function investmentDetails1(address _user) public view returns(InvestStruct[] memory){
        InvestStruct[] memory investInfo = new InvestStruct[](investment[_user].length);
        for(uint i = 0; i < investment[_user].length; i++){
            investInfo[i] = (investment[_user][i]);
        }
        return investInfo;
    }

    function withdrawalDetails1(address _user) public view returns(WithdrawalStruct[] memory){
        WithdrawalStruct[] memory withdrawalInfo = new WithdrawalStruct[](withdawal[_user].length);
        for(uint i = 0; i < withdawal[_user].length; i++){
            withdrawalInfo[i] = (withdawal[_user][i]);
        }
        return withdrawalInfo;
    }

    function currentInvest(address _user) public view returns(uint amount_USD, uint amount_YPLX){
        for(uint i = 0; i < investment[_user].length; i++){
           amount_USD += investment[_user][i].amount_USD;
           amount_YPLX += investment[_user][i].amount_YPLX;
        }
        for(uint i = 0; i < withdawal[_user].length; i++){
            amount_USD -= withdawal[_user][i].amount_USD;
            amount_YPLX -= withdawal[_user][i].amount_YPLX;           
        }
    }

    function totalInvest(address _user) public view returns(uint amount_USD, uint amount_YPLX){
        for(uint i = 0; i < investment[_user].length; i++){
           amount_USD += investment[_user][i].amount_USD;
           amount_YPLX += investment[_user][i].amount_YPLX;
        }
    }

    function totalWithdawal(address _user) public view returns(uint amount_USD, uint amount_YPLX){
        for(uint i = 0; i < withdawal[_user].length; i++){
            amount_USD += withdawal[_user][i].amount_USD;
            amount_YPLX += withdawal[_user][i].amount_YPLX;           
        }
    }

}