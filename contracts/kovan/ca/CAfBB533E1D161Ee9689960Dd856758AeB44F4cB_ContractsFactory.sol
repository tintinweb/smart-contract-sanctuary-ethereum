import "./WinAnswer.sol";
pragma solidity 0.8.0;

contract ContractsFactory {
    address[] public contracts;
    Referrals referrals;
    address platform;

    constructor(){
        platform = msg.sender;
    }

    function create() public returns(address) {
        WinAnswer winAnswer = new WinAnswer();
        contracts.push(address(winAnswer));
        referrals.addReferralOnNewContractCreation(address(winAnswer));
        return address(winAnswer);
    }

    function setReferrals(address _referrals) public {
        require(msg.sender == platform);
        referrals = Referrals(_referrals);
    }
}