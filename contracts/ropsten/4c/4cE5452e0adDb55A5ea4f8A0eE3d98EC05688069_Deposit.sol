pragma solidity >=0.7.0 <0.9.0;

interface cETH {

    // define functions of COMPOUND we'll be using

    function mint() external payable; // to deposit to compound
    function redeem(uint redeemTokens) external returns (uint); // to withdraw from compound

    //following 2 functions to determine how much you'll be able to withdraw
    function exchangeRateStored() external view returns (uint);
    function balanceOf(address owner) external view returns (uint256 balance);
}

struct AllBalances {
    uint balance;
    uint balanceWithInterest;
}

contract Deposit {
    address COMPOUND_CETH_ADDRESS = 0x859e9d8a4edadfEDb5A2fF311243af80F85A91b8;
    cETH ceth = cETH(COMPOUND_CETH_ADDRESS);

    event BalanceChanged(address indexed _from, uint _value, uint _interestValue);

    uint totalContractBalance = 0;

    function getContractBalance() public view returns(uint) {
        return totalContractBalance;
    }

    mapping(address => uint) balances;
    mapping(address => uint) depositTimestamps;

    function addBalance() public payable {
        balances[msg.sender] += msg.value;
        totalContractBalance += msg.value;
        depositTimestamps[msg.sender] = block.timestamp;
        ceth.mint{value: msg.value}();

    emit BalanceChanged(msg.sender, balances[msg.sender], getBalanceWithInterest(msg.sender));
    }

    function getBalance() public view returns(uint) {
        return balances[msg.sender];
    }

    function getBalanceWithInterest(address userAddress) public view returns(uint256) {
        return balances[userAddress] * ceth.exchangeRateStored() / 1e18;
    }

    function getAllBalance() external view returns(AllBalances memory) {
        return AllBalances(balances[msg.sender], getBalanceWithInterest(msg.sender));
    }

    function withdrawAll() public {
        address payable withdrawTo = payable(msg.sender);
        uint amountToTransfer = balances[msg.sender];

        totalContractBalance -= amountToTransfer;
        ceth.redeem(balances[msg.sender]);
        balances[msg.sender] = 0;
        emit BalanceChanged(msg.sender, balances[msg.sender], getBalanceWithInterest(msg.sender));
    }
}