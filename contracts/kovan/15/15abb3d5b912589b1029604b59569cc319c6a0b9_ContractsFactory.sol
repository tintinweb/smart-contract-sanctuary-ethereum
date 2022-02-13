import "./WinAnswer.sol";
pragma solidity 0.8.0;

contract ContractsFactory {
    string name;
    Referrals referralsList;
    address factory;

    constructor(){
        factory = msg.sender;
    }

    function create() public returns(address) {
        WinAnswer winAnswer = new WinAnswer();
        referralsList.addReferralOnNewContractCreation(address(winAnswer));
        return address(winAnswer);
    }

    function setReferrals(address _referrals) public {
        require(msg.sender == factory);
        referralsList = Referrals(_referrals);
    }

    function referrals() public view returns(address){
        return address(referralsList);
    }
}