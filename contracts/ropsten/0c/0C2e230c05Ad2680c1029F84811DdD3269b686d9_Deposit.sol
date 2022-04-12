pragma solidity >=0.7.0 <0.9.0;

//import "@openzeppelin/contracts/utils/math/SafeMath.sol";


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

    mapping(address => uint) depositBalances;
    mapping(address => uint) cEthBalances;

    function addBalance() public payable {
        ceth.mint{value: msg.value}();
        depositBalances[msg.sender] += msg.value;
        cEthBalances[msg.sender] += msg.value * 1e28 / ceth.exchangeRateStored();
    }

    function getExchangeRate() external view returns(uint) {
        return ceth.exchangeRateStored();
    }

    function getDepositBalance() public view returns(uint) {
        return depositBalances[msg.sender];
    }

    function getCEthBalance() public view returns(uint) {
        return cEthBalances[msg.sender];
    }

    function getBalance() public view returns(uint) {
        return getBalanceWithInterest(msg.sender);
    }

    function getBalanceWithInterest(address userAddress) public view returns(uint256) {
        return cEthBalances[userAddress] * (ceth.exchangeRateStored() / 1e28);
    }

    function getAllBalance() external view returns(AllBalances memory) {
        return AllBalances(depositBalances[msg.sender], getBalanceWithInterest(msg.sender));
    }

    function withdrawAll() public {
        uint amountToTransfer = depositBalances[msg.sender];
        ceth.redeem(depositBalances[msg.sender]);
        depositBalances[msg.sender] = 0;
        emit BalanceChanged(msg.sender, depositBalances[msg.sender], getBalanceWithInterest(msg.sender));
    }
}