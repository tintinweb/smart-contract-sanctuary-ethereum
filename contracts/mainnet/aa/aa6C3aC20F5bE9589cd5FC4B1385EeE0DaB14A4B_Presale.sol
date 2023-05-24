/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

interface TestToken {
    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
    function transfer(address recipient, uint256 amount) external returns(bool);

}

contract Presale{
    event TokenPurchased(address indexed _owner, uint256 _amount, uint256 _bnb);
    event ClaimedToken(address indexed _owner, uint256 _stakeId, uint256 _date);

    TestToken Token;

    bool public is_preselling;
    address payable owner;
    address payable tokenSource = payable(0x1625c7Fd27e19d48294AcD952d052fF81b288c50); 
    address payable fundreceiver = payable(0x9178f3E0E71c3Dca85A79800f76c7C68BfeaB602);
    uint256 soldTokens;
    uint256 sellingTokens=3_000_000 * 10**18;
    uint256 receivedFunds;
    uint256 priceInWEI=5000000000000;


    struct tokenVesting{
        uint256 amount;        
        uint256 date_added;     
        uint256 redeem_date;    
        uint256 redeem_count;
    }
    
    uint256 redemptionCount = 10; //4 times to redeem
    uint256 lockDays = 28; //1 month duration every redemption (total of 120 days or 4 months)
    uint256 rewardRate = 0; //20% reward for vesting the tokens

    uint256 public RecordId;
    mapping(uint256 => tokenVesting) idVesting; 
    mapping(uint256 => address) recordIdOwner;
    mapping(address => uint256) recordIdOwnerRev;  

    constructor(TestToken _tokenAddress)  {
        Token = _tokenAddress;
        owner = payable(msg.sender);
        is_preselling = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "invalid owner");
        _;
    }
    
    //buy tokens
    function tokensale() public payable returns(uint256)  {
        require(is_preselling, "pre sale is over.");
        require(recordIdOwnerRev[msg.sender] == 0 ,"Already Purchased from this wallet please use a different one");
        uint256 _amount =calc(msg.value);
        uint256 _totalTokens = _amount*10**18;
        require(soldTokens < sellingTokens,"Sold Out");
        require(soldTokens + _totalTokens < sellingTokens,"Purchase amount exceeds avaliable tokens");

        RecordId += 1; //auto increment for every record

        //save new vesting record
        tokenVesting storage _vesting = idVesting[RecordId];
        _vesting.amount = _totalTokens;
        _vesting.date_added = block.timestamp;
        _vesting.redeem_date = block.timestamp ;

        //track down the owner of the record id
        recordIdOwner[RecordId] = msg.sender;

        //save id with owner for future refrence
        recordIdOwnerRev[msg.sender] = RecordId;


        //transfer tokens to contract address
        Token.transferFrom(tokenSource, address(this), _totalTokens);

        
        soldTokens += _amount;
        receivedFunds += msg.value;

        emit TokenPurchased(msg.sender, _amount, msg.value);
        return RecordId;
    }

    function Redeem(uint256 _id) public returns(bool)  {
        
        //verify the owner of the stake record
        address _recordOwner = recordIdOwner[_id];
        require(_recordOwner == msg.sender, "invalid owner");

        tokenVesting storage _vesting = idVesting[_id];

        //validate if total redemption is not greater than 4 or (redemption count)
        require(_vesting.redeem_count < redemptionCount, "already redeemed");
        
        //validate if redemption date is ready
        uint256 _redeemDate = _vesting.redeem_date;  
        require(block.timestamp >= _redeemDate, "not yet ready to redeem");

        uint256 _redeemAmount = _vesting.amount / redemptionCount; //amount every redemption (divided by number of redemption or 4)

        _vesting.redeem_count += 1; //update count of redemption max of 4
        _vesting.redeem_date = _redeemDate + (lockDays * 1 days);// update date for next redemption +30 days 

        //tokens will be transferred to user's wallet address
        Token.transfer(msg.sender, _redeemAmount);

        emit ClaimedToken(msg.sender, _id, block.timestamp);
        return true;
    }
    
    function getTokenbalance(uint256 _id) public view returns(uint256){
        tokenVesting storage _vesting = idVesting[_id];
        uint256 _redeemAmount = _vesting.amount / redemptionCount;
        return _redeemAmount;

    }

    function viewfundreciever() public view returns(address){
        return fundreceiver;
    }
    function getBalance()  public onlyOwner {
        owner.transfer(address(this).balance);
    }
    
    function totalSoldTokens() public view returns(uint256){
        return soldTokens;
    }
    function totalReceivedFunds() public view returns(uint256){
        return receivedFunds;
    }

    function calc(uint256 _ethToSpendInWEI) public view returns(uint256){
        return _ethToSpendInWEI / priceInWEI;
    }

    function findRecordIds(address _yourAddress) public view returns(uint256){
        return recordIdOwnerRev[_yourAddress];
    }

    function nextRedeem(address _yourAddress) public view returns(uint256){
        uint256 _id=findRecordIds(_yourAddress);
        tokenVesting storage _vesting = idVesting[_id];
        return _vesting.redeem_date;
    }
    
    function ToLedger()  public onlyOwner {
        fundreceiver.transfer(address(this).balance);
    }

    function SwapPreSellingStatus() public onlyOwner {
        is_preselling = !is_preselling;
    }

    function updatePrice(uint256 _priceInWEI) public onlyOwner {
        priceInWEI=_priceInWEI;
    }

}