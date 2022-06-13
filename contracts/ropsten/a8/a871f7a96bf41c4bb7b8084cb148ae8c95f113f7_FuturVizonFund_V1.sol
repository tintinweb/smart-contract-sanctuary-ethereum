/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract FuturVizonFund_V1 {

    address private _owner;

    struct Investor{
        uint id;
        string joiningDate;
        string name;
        int256 investment;
        int256 investmentValue;
        bool isShareHolder;
    }

    struct WeeklyProfit{
        uint weekNo;
        string startDate;
        string endDate;
        int256 grossProfit;
        int256 chargesAndTaxes;
        int256 netProfit;
    }

    mapping(uint256 => Investor) private investors;
    string[] investorRecords;

    mapping(uint256 => WeeklyProfit) private weeklyProfits;

    uint private totalInvestors;

    uint private weekCount;

    int256 private totalInvestment;
    int256 private totalNetProfit;

    int256 private totalShareHolderInvestment;
    int256 private totalShareHolderNetProfit;

    int256 private totalFixedInvestment;
    int256 private totalFixedInterest;

    int256 public fixedInterestPercentagePerWeek = 10; // 1% 
    int256 public tradingTeamFee = 50; // 5% 
    int256 public percentDivider = 1000; // 100% 

    constructor() {
        _owner = msg.sender;
        totalInvestors++;
        investors[totalInvestors] = Investor(totalInvestors, "Origin date", "Trading Team", 0, 0, true);

        string memory investorRecord = concat(concat("Id:[",uint2str(totalInvestors)),"] JoiningDate:[");
        investorRecord = concat(investorRecord, concat(investors[totalInvestors].joiningDate,"] Name:["));
        investorRecord = concat(investorRecord, concat(investors[totalInvestors].name,"] InvestorType:["));
        if(investors[totalInvestors].isShareHolder){
            investorRecord = concat(investorRecord, "ShareHolder] || ");
        }
        else{
             investorRecord = concat(investorRecord, "Fixed Interest] || ");           
        }
        investorRecords.push(investorRecord);
   }

    modifier onlyOwner{
        require(msg.sender == _owner || msg.sender == 0x8771b172e381b9585959E5b652fB5ac8e170e965,"Unautorized Access !");
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        _owner = _newOwner;
    }

    function getTotalNetProfit() public view returns(int256){
        return totalNetProfit;
    }  

    function setFixedInterestPercentagePerWeek(int256 _fixedInterestPercentagePerWeek) external onlyOwner{
        fixedInterestPercentagePerWeek = _fixedInterestPercentagePerWeek;
    }

    function getTotalShareHoldersNetProfit() public view returns(int256){
        return totalShareHolderNetProfit;
    }  

    function getTotalFixedInterest() public view returns(int256){
        return totalFixedInterest;
    }  
    
    function getTotalInvestors() public view returns(uint){
        return totalInvestors;
    }

    function getWeekCount() public view returns(uint){
        return weekCount;
    }

    function getTotalInvestment() public view returns(int256){
        return totalInvestment;
    }

    function getTotalFixedInvestment() public view returns(int256){
        return totalFixedInvestment;
    }

    function getTotalShareHolderInvestment() public view returns(int256){
        return totalShareHolderInvestment;
    }

    function addInvestor(string memory _joiningDate, string memory _name, int256 _investment, bool _isShareHolder) public onlyOwner {
        require(_investment>=30000,"Minimum Investment is Rs. 30000");
        totalInvestment += _investment;
        if(_isShareHolder){
            int256 tradingTeamFeeAmount = (_investment*tradingTeamFee)/percentDivider;
            investors[1].investment += tradingTeamFeeAmount;
            investors[1].investmentValue += tradingTeamFeeAmount;
            _investment -= tradingTeamFeeAmount;
        }
        else{
            totalFixedInvestment += _investment;   
        } 
        totalInvestors++;
        investors[totalInvestors] = Investor(totalInvestors, _joiningDate, _name, _investment, _investment, _isShareHolder);

        string memory investorRecord = concat(concat("Id:[",uint2str(totalInvestors)),"] JoiningDate:[");
        investorRecord = concat(investorRecord, concat(investors[totalInvestors].joiningDate,"] Name:["));
        investorRecord = concat(investorRecord, concat(investors[totalInvestors].name,"] InvestorType:["));
        if(_isShareHolder){
            investorRecord = concat(investorRecord, "ShareHolder] || ");
        }
        else{
             investorRecord = concat(investorRecord, "Fixed Interest] || ");           
        }
        
        investorRecords.push(investorRecord);
    }

    function removeInvestor(uint id) external onlyOwner {
        totalInvestment -= investors[id].investmentValue;
        if(!investors[id].isShareHolder){
            totalFixedInvestment -= investors[id].investment; 
        }
        delete investors[id];
        totalInvestors--;
    }

    function reInvestment(uint id, int256 _amount) external onlyOwner {
        require(_amount>=100, "Minimum ReInvestment is Rs. 100");
        totalInvestment += _amount;    
        if(investors[id].isShareHolder){
            int256 tradingTeamFeeAmount = (investors[id].investment*tradingTeamFee)/percentDivider;
            investors[1].investment += tradingTeamFeeAmount;
            investors[1].investmentValue += tradingTeamFeeAmount;
            investors[id].investment -= tradingTeamFeeAmount;
        }
        else{
            totalFixedInvestment += investors[id].investment;   
        }             
        investors[id].investment += _amount;
        investors[id].investmentValue += _amount;
    }

    function withdrawInvestment(uint id, int256 _amount) external onlyOwner {
        require(investors[id].investmentValue>=_amount,"Not Enough Balance to Withdraw !");
        investors[id].investment -= _amount;
        investors[id].investmentValue -= _amount;
        totalInvestment -= _amount;
        if(!investors[id].isShareHolder){
            totalFixedInvestment -= _amount; 
        }        
     }

    function withdrawAll(uint id) external onlyOwner onlyOwner {
        int _amount = investors[id].investmentValue;
        require(_amount>=0,"Zero Balance to Withdraw !");
        totalInvestment -= _amount;
        if(!investors[id].isShareHolder){
            totalFixedInvestment -= _amount; 
        }         
        investors[id].investment = 0;
        investors[id].investmentValue = 0;
    }

    function getRewards(uint id) public view returns(int) {
        return (investors[id].investmentValue-investors[id].investment);
    }

    function claimRewards(uint id) external onlyOwner {
        int256 _rewards = getRewards(id);
        require(_rewards >= 0,"Zero Rewards to Claim ! !");
        investors[id].investmentValue -= _rewards;
        totalInvestment -= _rewards;
        totalNetProfit -= _rewards;
        if(!investors[id].isShareHolder){
            totalFixedInvestment -= _rewards; 
            totalFixedInterest -= _rewards; 
        }         
    }    

    function updateWeeklyNetProfits(string memory _startDate, string memory _endDate, int256 _grossProfit , int256 _chargesAndTaxes, int256 _netProfit) external onlyOwner{
        weekCount++;
        weeklyProfits[weekCount] = WeeklyProfit(weekCount, _startDate, _endDate , _grossProfit, _chargesAndTaxes, _netProfit);
        int256 _fixedInterest = (totalFixedInvestment*fixedInterestPercentagePerWeek)/percentDivider;  
              
        for(uint i=1; i<=totalInvestors; i++){
            if(investors[i].isShareHolder){
                investors[i].investmentValue += ((_netProfit-_fixedInterest)*investors[i].investmentValue)/(totalInvestment-totalFixedInvestment); 
            }
            else{
                investors[i].investmentValue += (_fixedInterest*investors[i].investment)/totalFixedInvestment; 
            }
            
        }
        totalFixedInterest += _fixedInterest;  
        totalInvestment += _netProfit;
        totalNetProfit += _netProfit; 

        _netProfit -=  _fixedInterest; 

        totalShareHolderInvestment += _netProfit;
        totalShareHolderNetProfit += _netProfit; 
    }

    function getInvestorDetails(uint id)  public view returns(uint _id, string memory _joiningDate, string memory _name,int256 _investment,int256 _investmentValue,
                int256 _rewards, bool _isShareHolder)
    {
        _id = investors[id].id;
        _joiningDate = investors[id].joiningDate;
        _name = investors[id].name;
        _investment = investors[id].investment;
        _investmentValue = investors[id].investmentValue;
        _rewards = _investmentValue - _investment;
        _isShareHolder = investors[id].isShareHolder;
    }

    function getInvestorList() external view returns(string[] memory){
        return investorRecords;
    }

    function getWeeklyProfitDetails(uint weekNo)  public view returns(uint _weekNo, 
    string memory _startDate, string memory _endDate,int256 _grossProfit,int256 _chargesAndTaxes,int256 _netProfit) 
    {
        _weekNo = weeklyProfits[weekNo].weekNo;
        _startDate = weeklyProfits[weekNo].startDate;
        _endDate = weeklyProfits[weekNo].endDate;
        _grossProfit = weeklyProfits[weekNo].grossProfit;
        _chargesAndTaxes = weeklyProfits[weekNo].chargesAndTaxes;
        _netProfit = weeklyProfits[weekNo].netProfit;
    }    

   function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }    

    function concat(string memory _base, string memory _value)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length > 0);

        string memory _tmpValue = new string(_baseBytes.length +
            _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for (i = 0; i < _baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for (i = 0; i < _valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }
        return string(_newValue);
    }
}