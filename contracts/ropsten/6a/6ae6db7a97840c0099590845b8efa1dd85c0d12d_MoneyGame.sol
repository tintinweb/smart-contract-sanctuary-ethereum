// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC20.sol";

contract MoneyGame{
    event event_add_members(string username,address userAddress, uint256 Value);
    event event_receive(address Donor,uint256 Value);

    string public boss_name;
    address payable public boss_address;
    struct member{
        string name;
        address payable user_address;
        uint256 inittime; //匯入時間
        uint256 principal; //本金
        uint256 interest; //利息
    }

    mapping(address=>string) address_name;
    mapping(string=>member) memberObj;

    modifier IsBoss() {
        require(msg.sender==boss_address,"You are not the boss!");
        _;
    }

    //複投
    function deposit(string memory username) external payable{
        member memory s = memberObj[address_name[msg.sender]];

        require(keccak256(abi.encode(s.name)) == keccak256(abi.encode(username)) , "invalid member");
        require(msg.value > 0, "no money");

        memberObj[username].principal += msg.value;
        memberObj[username].inittime = block.timestamp;
        memberObj[username].interest = 0;
    }
    
    //投資
    function invest(string memory username) external payable{
        
        require(msg.value > 0, "no money");

        address_name[msg.sender] = username;
        memberObj[username].name = username;
        memberObj[username].user_address = payable(msg.sender);
        memberObj[username].principal = msg.value;
        memberObj[username].inittime = block.timestamp;
        memberObj[username].interest = 0;
        emit event_add_members(username, msg.sender, msg.value);
    }
    
    // 天數
    function getDaysCount() external view returns(uint256) {
        member memory s = memberObj[address_name[msg.sender]];

        return (block.timestamp - s.inittime) / 1 days;
    }

    // 本金 + 利息
    function getMyBalance() external view returns(uint256) {
        member memory s = memberObj[address_name[msg.sender]];

        uint256 total = s.principal + this.getMyInterest();

        return total;
    }

    // 利息
    function getMyInterest() external view returns(uint256) {
        member memory s = memberObj[address_name[msg.sender]];

        return mul(s.principal) * this.getDaysCount();
    }
    
    function mul(uint256 _amount) private pure returns(uint256) {
        return _amount * 10 / 100;
    }
   
    //出金
    function Withdraw() external returns(uint256){
        uint256 balance = this.getMyBalance();
        payable(msg.sender).transfer(balance);
        string memory name = address_name[msg.sender];
        memberObj[name].principal = 0;
        return balance;
    }

    constructor(string memory name){
        boss_name = name;
        boss_address = payable(msg.sender);
    }
   
    fallback() external payable {
    }
    
    receive() external payable {
        emit event_receive(msg.sender,msg.value);
    }

    function Destroy() external IsBoss{
        selfdestruct(boss_address);
    }

}