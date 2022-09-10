// SPDX-License-Identifier:MIT
pragma solidity ^0.8.3;

import "./PiggyBank.sol";

contract PiggyBankFactory {
    PiggyBank[] public banks;
    mapping(address =>  PiggyBank[]) individualBanks;
    address owner;
    address devAddress;
    bool devAddressAdded;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "access for only owner");
        _;
    }

    event newClone(PiggyBank indexed , uint256 indexed position, string indexed purpose);
    event devAddressUpdated(address indexed newAddress);

    //@dev This functions creates piggy banks with unique addresses
    function createBank(uint _timeLock, string memory _savingPurpose) external returns (PiggyBank newPiggyBank, uint length) {
        require(devAddressAdded == true, "contract not open to receive funds");

        address ownerAddress = msg.sender;

        newPiggyBank = new PiggyBank(ownerAddress, devAddress, _timeLock, _savingPurpose);
        banks.push(newPiggyBank);

        length = banks.length;

        individualBanks[msg.sender].push(newPiggyBank);

        emit newClone(newPiggyBank, length, _savingPurpose);
    }

    function bankCount() external view returns (uint totalBank) {
        totalBank = banks.length;
    }

    function getBanks() external view returns (PiggyBank[] memory allBanks) {
        allBanks = banks;
    }

    /// @dev get piggy banks created by an address
    function getUserBanks(address _address) external view returns(PiggyBank[] memory ) {
        return individualBanks[_address];
    }

    function updateDevAddress(address _devAddress) external onlyOwner {
        devAddress = _devAddress;
        devAddressAdded = true;

        emit devAddressUpdated(_devAddress);
    }

    function showDevAddress() external view returns (address addr) {
        addr = devAddress;
    }

}

// SPDX-License-Identifier:MIT

pragma solidity ^0.8.3;

import "./IStable.sol";


contract PiggyBank {
    event Deposit(uint amount);
    event Withdraw(uint amount);

    string public savingPurpose;

    address public immutable owner;
    address immutable devAddr;
    uint immutable timeLock;

    constructor(address ownerAddress, address _devAdd, uint _timeLock, string memory _savingPurpose) {
        owner = ownerAddress;
        devAddr = _devAdd;
        timeLock =  block.timestamp + (_timeLock * 1 days);
        savingPurpose = _savingPurpose;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "requires only owner");
        _;
    }

    function deposit() external payable{
       require(msg.value > 0, "You can't deposit less than 0");
    }

    
    //@dev function to withdraw funds after lock time is reached
    function safeWithdraw() external onlyOwner {
        require(block.timestamp > timeLock, "Lock period not reached");
        require(msg.sender != address(0), "You cant withdraw into zero address");
        require(address(this).balance > 0, "no funds deposited");

        uint bal = address(this).balance;
        uint commission = savingCommission();

        uint withdrawable = bal - commission;

        payable(owner).transfer(withdrawable);
        payable(devAddr).transfer(commission);

        emit Withdraw(withdrawable);
    }

    function savingCommission () private view returns(uint commission) {
        commission = (address(this).balance * 1) / 1000;
    }

    //@dev function called for emergency withdrawal and 15% is withdrawn as chanrges (for penal fee) 
    function emergencyWithdawal () external onlyOwner {
        uint contractBal = address(this).balance;
        uint penalFee = penalPercentage();

        uint withdrawBal = contractBal - penalFee;

        payable(owner).transfer(withdrawBal);

        devWithdraw(penalFee);
        
    }

    //@dev this function allows dev to withdraw the percentage gotten after emergency funds have been withdrawn 
    function devWithdraw (uint _penalFee) internal {
        require(msg.sender != address(0), "Can't withdraw to this addess");

        payable(devAddr).transfer(_penalFee);
    }

     function penalPercentage () private view returns(uint percent){
        percent = (address(this).balance / 15) * 100;
    }

    function getContractBalance() external view returns (uint bal) {
        bal = address(this).balance;
    }

    receive() external payable {
        emit Deposit(msg.value);
    }

    // Stable coins functions

    function depositToken(address _token,uint _amount) public {
        IERC20(_token).approve(address(this), _amount);
        IERC20(_token).transferFrom(msg.sender,address(this),_amount);
    }

     function safeWithdrawToken(address _token) external {
        require(block.timestamp > timeLock, "Lock period not reached");
        require(msg.sender != address(0), "You cant withdraw into zero address");

        uint conractTokenBalance = getTokenBalance(_token);
        uint commission = savingTokenCommission(_token);
        uint transferToken = conractTokenBalance - commission;

        IERC20(_token).approve(msg.sender, transferToken);
        IERC20(_token).transferFrom(address(this),msg.sender,transferToken);
        devWithdrawToken(_token, commission);
    }

    function savingTokenCommission(address _token) private view returns(uint commission) {
        uint tokenBalance = getTokenBalance(_token);
        commission = (tokenBalance * 1) / 1000;
    }

    function emergencyWithdawalToken (address _token) external {
        require(msg.sender != address(0), "You cant withdraw into zero address");

        uint contractTokenBalance = getTokenBalance(_token);
        uint penalFee = tokenPenalPercentage(_token);
        uint transferable = contractTokenBalance - penalFee;
        
        IERC20(_token).approve(msg.sender, transferable);
        IERC20(_token).transferFrom(address(this),msg.sender,transferable);
        devWithdrawToken(_token, penalFee);
    }

    function tokenPenalPercentage (address _token) private view returns(uint percent){
        uint tokenBalance = getTokenBalance(_token);
        percent = (tokenBalance / 15) * 100;
    }


    function devWithdrawToken (address _token, uint _devToken) private {
        IERC20(_token).approve(devAddr, _devToken);
        IERC20(_token).transferFrom(address(this),devAddr,_devToken);
    }

    function getTokenBalance(address _token) public view returns(uint) {
        return IERC20(_token).balanceOf(address(this)); 
    }    
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

interface IERC20 
{

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);


}