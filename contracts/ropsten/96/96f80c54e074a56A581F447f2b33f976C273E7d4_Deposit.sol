pragma solidity >=0.7.0 <0.9.0;

interface cETH {
    function mint() external payable;
    function redeem(uint redeemTokens) external returns (uint);
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

    mapping(address => uint) balances;
    mapping(address => uint) cethBalances;

    function addBalance() public payable {
        cethBalances[msg.sender] += msg.value / ceth.exchangeRateStored() / 1e18;
        ceth.mint{value: msg.value}();
        emit BalanceChanged(msg.sender, balances[msg.sender], getBalanceWithInterest(msg.sender));
    }

    function getExchangeRate() external view returns(uint) {
        return ceth.exchangeRateStored();
    }

    function getBalance() public view returns(uint) {
        return getBalanceWithInterest(msg.sender);
    }

    function getBalanceWithInterest(address userAddress) public view returns(uint256) {
        return cethBalances[msg.sender] * ceth.exchangeRateStored() / 1e18;
    }

    function getAllBalance() external view returns(AllBalances memory) {
        return AllBalances(balances[msg.sender], getBalanceWithInterest(msg.sender));
    }

    function withdrawAll() public {
        uint amountToTransfer = balances[msg.sender];
        ceth.redeem(balances[msg.sender]);
        balances[msg.sender] = 0;
        emit BalanceChanged(msg.sender, balances[msg.sender], getBalanceWithInterest(msg.sender));
    }
}