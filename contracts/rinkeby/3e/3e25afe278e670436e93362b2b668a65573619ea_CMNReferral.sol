/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

/**
 *Submitted for verification at BscScan.com on 2022-02-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface Token {
    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function transfer(address, uint256) external returns (bool);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface Staking {
        function isBlackListForRefer(address) external view returns(bool);
}

contract CMNReferral is Ownable{

    struct ReferralEarning{
        address[] stakingAddress;
        address[] user;
        uint[] amount;
        uint[] timestamp;
    }

    mapping(address => bytes3) userReferralCode;
    mapping(bytes3 => address) public getUserByReferralCode;
    mapping(address => address) userReferral; // which refer user used
    mapping(address => address[]) userReferrales; // referral address which use users address
    mapping(address => uint256) public totalReferalAmount; // get my total referal amount
    mapping(address => ReferralEarning) referralEarning;
    uint256[] public referrals =[800,400,200];
    address public depositToken;
    address[] public stakingContract;


    function getReferCode() public {
        require(userReferralCode[msg.sender] == 0, "Already have refer code");
        bytes3 rand = bytes3(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty, block.number)));
        userReferralCode[msg.sender] = bytes3(rand);
        getUserByReferralCode[rand] = msg.sender;
    }

    function getUserReferralCode(address userAddress) public view returns(bytes3){
        return userReferralCode[userAddress];
    }

    function getUserReferralInformation(address userAddress) public view returns(address[] memory, address[] memory, uint[] memory, uint[] memory){
        return (referralEarning[userAddress].stakingAddress, referralEarning[userAddress].user, referralEarning[userAddress].amount, referralEarning[userAddress].timestamp);
    }

    function setDepositToken(address _token) public onlyOwner{
        depositToken = _token;
    }

    function addNewLevel(uint levelRate) public onlyOwner{
        referrals.push(levelRate);
    }

    function updateExistingLevel(uint index, uint levelRate) public onlyOwner{
        referrals[index] = levelRate;
    }

    function addNewStaking(address _stakingAddress) public onlyOwner{
        stakingContract.push(_stakingAddress);
    }

    function setUserReferral(address beneficiary, address referral) public returns(bool){
        bool validCaller = false;
        for(uint i = 0; i < stakingContract.length; i++){
            if(stakingContract[i] == msg.sender){
                validCaller = true;
            }   
        }
        require(validCaller, "Only Staking Contract");
        userReferral[beneficiary] = referral;
        return true;
    }

    function setReferralAddressesOfUsers(address beneficiary, address referral) public returns(bool){
        bool validCaller = false;
        for(uint i = 0; i < stakingContract.length; i++){
            if(stakingContract[i] == msg.sender){
                validCaller = true;
            }   
        }
        require(validCaller, "Only Staking Contract");
        userReferrales[referral].push(beneficiary);
        return true;
    }

    function getUserReferral(address user) public view returns(address){
        return userReferral[user];
    }

    function getReferralAddressOfUsers(address user) public view returns(address[] memory){
        return userReferrales[user];
    }

    function getTotalStakingContracts() public view returns(uint, address[] memory){
        return (stakingContract.length, stakingContract);
    }

    function payReferral(address _userAddress, address _secondaryAddress, uint _index, uint256 _mainAmount) public returns(bool) {
        bool validCaller = false;
        for(uint i = 0; i < stakingContract.length; i++){
            if(stakingContract[i] == msg.sender){
                validCaller = true;
            }   
        }
        require(validCaller, "Only Staking Contract");
        if( _index >= referrals.length ){
            return true;
        }else {
            if(userReferral[_userAddress] != address(0)){
                uint256 transferAmount =  _mainAmount * referrals[_index] /10000;
                referralEarning[userReferral[_userAddress]].stakingAddress.push(msg.sender);
                referralEarning[userReferral[_userAddress]].user.push(_secondaryAddress);
                referralEarning[userReferral[_userAddress]].amount.push(transferAmount);
                referralEarning[userReferral[_userAddress]].timestamp.push(block.timestamp);
                if(!Staking(msg.sender).isBlackListForRefer(userReferral[_userAddress])){
                    require(
                    Token(depositToken).transfer(userReferral[_userAddress], transferAmount),
                    "Could not transfer referral amount"
                    );
                    totalReferalAmount[userReferral[_userAddress]] = totalReferalAmount[userReferral[_userAddress]] + (transferAmount); 
                }
                payReferral(userReferral[_userAddress], _secondaryAddress, _index +1,_mainAmount);
                return true;
            }else{
                return false;
            }
        }
    }

    function transferAnyBEP20Tokens(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        Token(_tokenAddr).transfer(_to, _amount);
    }
}