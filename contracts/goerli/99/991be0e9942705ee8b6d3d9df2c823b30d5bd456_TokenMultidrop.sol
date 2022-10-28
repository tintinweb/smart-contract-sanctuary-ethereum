// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./Ownable.sol";

contract TokenMultidrop is Ownable {

    uint256 public oneDayMembershipFee = 0;
    uint256 public sevenDayMembershipFee = 0;
    uint256 public oneMonthMembershipFee = 0;
    uint256 public lifetimeMembershipFee = 0;

    uint256 public tokenHoldersDiscountPer  = 0;
    uint256 public rate = 0;
    uint256 public dropUnitPrice = 0;
    uint256 public freeTrialLimit = 100;

    mapping (address => uint256) public tokenTrialDrops;
    mapping (address => uint256) public userTrialDrops;

    IERC20 public token;

    mapping (address => uint256) public membershipExpiryTime;
    mapping (address => bool) public isGrantedPremiumMember;

    address[] public vipMemberList;

    event BecomeVIPMember(address indexed _user, uint256 _day, uint256 _fee, uint256 _time);
    event TokenAirdrop (address indexed _user, address indexed _tokenAddress, uint256 _totalTransfer, uint256 _time);
    event NFTsAirdrop (address indexed _user, address indexed _tokenAddress, uint256 _totalTransfer, uint256 _time);

    function setMembershipFees(uint256 _oneDayFee, uint256 _sevenDayFee, uint256 _oneMonthFee, uint256 _lifetimeFee) public onlyOwner {
        oneDayMembershipFee = _oneDayFee;
        sevenDayMembershipFee = _sevenDayFee;
        oneMonthMembershipFee = _oneMonthFee;
        lifetimeMembershipFee = _lifetimeFee;
    }

    function setFreeTrialLimit(uint256 _limit) public onlyOwner {
        freeTrialLimit = _limit;
    }

    function setTokenHoldersDiscountPer(uint256 _per) public onlyOwner{
        tokenHoldersDiscountPer = _per;
    }

    function initialize(address _token) public onlyOwner {
        require(_token != address(0), "Invalid address");
        token = IERC20(_token);
    }

    function getVIPMembershipFee(uint256 _days) public view returns(uint256){
      if(_days == 1){
          return oneDayMembershipFee;
      }else if(_days ==7){
          return sevenDayMembershipFee;
      }else if(_days == 31){
          return oneMonthMembershipFee;
      }else{
          return lifetimeMembershipFee;
      }
    }

    function checkIsPremiumMember(address _addr) public view returns(bool isMember) {
        return membershipExpiryTime[_addr] >= block.timestamp || isGrantedPremiumMember[_addr];
    }

    function tokenHasFreeTrial(address _addressOfToken) public view returns(bool hasFreeTrial) {
        return tokenTrialDrops[_addressOfToken] < freeTrialLimit;
    }

    function userHasFreeTrial(address _addressOfUser) public view returns(bool hasFreeTrial) {
        return userTrialDrops[_addressOfUser] < freeTrialLimit;
    }

    function getRemainingTokenTrialDrops(address _addressOfToken) public view returns(uint256 remainingTrialDrops) {
        if(tokenHasFreeTrial(_addressOfToken)) {
            return freeTrialLimit - tokenTrialDrops[_addressOfToken];
        } 
        return 0;
    }

    function getRemainingUserTrialDrops(address _addressOfUser) public view returns(uint256 remainingTrialDrops) {
        if(userHasFreeTrial(_addressOfUser)) {
            return freeTrialLimit - userTrialDrops[_addressOfUser];
        }
        return 0;
    }

    function becomeMember(uint256 _day) public payable returns(bool success) {
        uint256 _fee;
        if(_day == 1){
            _fee = oneDayMembershipFee;
        }else if(_day == 7){
            _fee = sevenDayMembershipFee;
        }else if(_day == 31){
            _fee = oneMonthMembershipFee;
        }else {
            _fee = lifetimeMembershipFee;
        }
        require(checkIsPremiumMember(msg.sender) != true, "Is already premiumMember member");
        if(token.balanceOf(msg.sender) > 0){
            _fee = _fee * tokenHoldersDiscountPer / 100;
        } 
        require(msg.value >= _fee, "Not Enough Fee Sent");
        membershipExpiryTime[msg.sender] = block.timestamp + (_day * 1 days);
        vipMemberList.push(msg.sender);
        isGrantedPremiumMember[msg.sender] = true;
        emit BecomeVIPMember(msg.sender, _day, _fee, block.timestamp);
        return true;
    }

    function setServiceFeeRate(uint256 _newRate) public onlyOwner returns(bool success) {
        require(_newRate > 0,"Rate must be greater than 0");
        dropUnitPrice = _newRate;
        return true;
    }

    function erc20Airdrop(address _addressOfToken,  address[] memory _recipients, uint256[] memory _values, uint256 _totalToSend, bool _isDeflationary) public payable {
        require(_recipients.length == _values.length, "Total number of recipients and values are not equal");
        uint256 price = _recipients.length * dropUnitPrice;
        bool isPremiumOrListed = checkIsPremiumMember(msg.sender);
        bool eligibleForFreeTrial = tokenHasFreeTrial(_addressOfToken) && userHasFreeTrial(msg.sender);
        require(msg.value >= price || isPremiumOrListed, "Not enough funds sent with transaction!");
        if((eligibleForFreeTrial || isPremiumOrListed) && msg.value > 0) {
            payable(msg.sender).transfer(msg.value);
        } 
      
        if(!_isDeflationary) {
            IERC20(_addressOfToken).transferFrom(msg.sender, address(this), _totalToSend);
            for(uint i = 0; i < _recipients.length; i++) {
                IERC20(_addressOfToken).transfer(_recipients[i], _values[i]);
            }
            if(IERC20(_addressOfToken).balanceOf(address(this)) > 0) {
                IERC20(_addressOfToken).transfer(msg.sender,IERC20(_addressOfToken).balanceOf(address(this)));
            }
        } else {
            for(uint i=0; i < _recipients.length; i++) {
                IERC20(_addressOfToken).transferFrom(msg.sender, _recipients[i], _values[i]);
            }
        }      
        if( !eligibleForFreeTrial && !isPremiumOrListed) {
            payable(owner()).transfer(_recipients.length * dropUnitPrice);   
        }
        if(tokenHasFreeTrial(_addressOfToken)) {
            tokenTrialDrops[_addressOfToken] += _recipients.length;
        }
        if(userHasFreeTrial(msg.sender)) {
            userTrialDrops[msg.sender] += _recipients.length;
        }
        emit TokenAirdrop(msg.sender, _addressOfToken, _recipients.length, block.timestamp);
    }

    function NFTAirdrop(address _addressOfNFT, address[] memory _recipients, uint256[] memory _tokenIds, uint256[] memory _amounts, uint8 _type) public payable {
        require(_recipients.length == _tokenIds.length, "Total number of recipients and total number of NFT IDs are not the same"); 
        bool eligibleForFreeTrial = tokenHasFreeTrial(_addressOfNFT) && userHasFreeTrial(msg.sender);   
        uint256 price = _recipients.length * dropUnitPrice;
        bool isPremiumOrListed = checkIsPremiumMember(msg.sender);
        require(msg.value >= price || isPremiumOrListed, "Not enough funds sent with transaction!");       
        if( (eligibleForFreeTrial || isPremiumOrListed) && msg.value > 0) {
            payable(msg.sender).transfer(msg.value);
        }  
        if(_type == 1){
            require(_recipients.length == _amounts.length, "Total number of recipients and total number of amounts are not the same");
            for(uint i = 0; i < _recipients.length; i++) {
                IERC1155(_addressOfNFT).safeTransferFrom(msg.sender, _recipients[i], _tokenIds[i], _amounts[i], "");
            }
        }else{
            for(uint i = 0; i < _recipients.length; i++) {          
                IERC721(_addressOfNFT).transferFrom(msg.sender, _recipients[i], _tokenIds[i]);
            }
        }                 
        if(!eligibleForFreeTrial && !isPremiumOrListed) {
            payable(owner()).transfer(_recipients.length * dropUnitPrice); 
        }
        if(tokenHasFreeTrial(_addressOfNFT)) {
            tokenTrialDrops[_addressOfNFT] += _recipients.length;
        }
        if(userHasFreeTrial(msg.sender)) {
            userTrialDrops[msg.sender] += _recipients.length;
        }
        emit NFTsAirdrop(msg.sender, _addressOfNFT, _recipients.length, block.timestamp);
    }

    function withdraw() public onlyOwner returns(bool success) {
        payable(owner()).transfer(address(this).balance);
        return true;
    }
}