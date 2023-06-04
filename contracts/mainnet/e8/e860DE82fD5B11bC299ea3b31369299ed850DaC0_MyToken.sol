// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract MyToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public totalContributed;
    uint256 public totalDistributed;
    uint256 public totalextraContributed;
    address public feeaddress = 0x02E91130B051E7B5FE703b005025Eb2ec9E4E159;
    AggregatorV3Interface internal priceFeed;
    uint256 public feecheck;

   
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public coinrefund;
    event Received(address indexed from, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() {
        name = "Shadow Greens";
        symbol = "SGRN";
        decimals = 18;
        totalSupply = 100000000000000000000000000000000000000000000000000 * 10 ** uint256(decimals);
        balanceOf[address(this)] = totalSupply;
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    }

    function openposition() public payable
    {
        require(coinrefund[msg.sender] == 0);
        (uint80 roundID, int price,uint startedAt,uint timeStamp,uint80 answeredInRound) = priceFeed.latestRoundData();
        uint256 rate = uint256(price);
        uint256 amount = ((msg.value) * rate);
        require(totalSupply >= amount, "Insufficient supply");
        coinrefund[msg.sender] = msg.value;
        emit Received(msg.sender, msg.value);
        balanceOf[msg.sender] += amount;
        balanceOf[address(this)] -= amount;
        totalSupply -= amount;
        totalContributed += msg.value;
        totalDistributed += amount;
        emit Transfer(address(this), msg.sender, amount);
    }

    function enlargeposition() public payable
    {
        (uint80 roundID, int price,uint startedAt,uint timeStamp,uint80 answeredInRound) = priceFeed.latestRoundData();
        uint256 rate = uint256(price);
        uint256 amount = ((msg.value) * rate);
        require(totalSupply >= amount, "Insufficient supply");
        emit Received(msg.sender, msg.value);
        balanceOf[msg.sender] += amount;
        balanceOf[address(this)] -= amount;
        totalSupply -= amount;
        totalextraContributed += msg.value;
        totalDistributed += amount;
        emit Transfer(address(this), msg.sender, amount);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;   
        emit Transfer(msg.sender, _to, _value);   
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0));     
        allowance[msg.sender][_spender] = _value;      
        emit Approval(msg.sender, _spender, _value);      
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        require(_to != address(0));      
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;     
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function send(address payable _receiver, uint256 ethToReturn) public payable {
        _receiver.transfer(ethToReturn);
    }

    function closeposition(uint256 value) public payable {
        (uint80 roundID, int price,uint startedAt,uint timeStamp,uint80 answeredInRound) = priceFeed.latestRoundData();
        uint256 rate2 = uint256(price);
        uint256 amount2 = (value / rate2);
        uint256 coinrefundamount = coinrefund[msg.sender]; 
        require(amount2 >= coinrefundamount);   
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        require(msg.value >= coinrefundamount/100);
        emit Received(msg.sender, msg.value);
        send(payable(feeaddress), msg.value);
        balanceOf[msg.sender] -= value;
        balanceOf[address(this)] += value;
        totalContributed -= coinrefundamount;
        totalSupply += value;
        totalDistributed -= value;
        coinrefund[msg.sender] = 0;
        send(payable(msg.sender), coinrefundamount);
        emit Transfer(msg.sender, address(this), value);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}