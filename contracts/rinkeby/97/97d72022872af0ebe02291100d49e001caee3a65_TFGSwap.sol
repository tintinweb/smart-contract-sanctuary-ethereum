/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

// File: @chainlink/contracts/src/v0.5/interfaces/AggregatorV3Interface.sol

pragma solidity >=0.5.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

// File: Token.sol

pragma solidity ^0.5.0;

contract Token {
    string  public name = "TFG Token";
    string  public symbol = "TFG";
    uint256 public totalSupply = 1000000000000000000000000; // 1 million tokens
    uint8   public decimals = 18;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}
// File: TFGSwap.sol

pragma solidity ^0.5.0;



contract TFGSwap {
    string public name = "TFGSwap Cryptocurrency Exchange";
    Token public token;
    uint public rate = 0;
    AggregatorV3Interface internal priceFeed;
    

    event TokensBought(
        address account,
        address token,
        uint amount,
        uint rate
    );

    event TokensSold(
        address account,
        address token,
        uint amount,
        uint rate
    );

    constructor(Token _token) public {
        token = _token;
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    }

    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price/100000000;
    }

    function buyTokens(uint n_tokensToBuy) public payable {
        // Calculate the number of tokens to buy
        
        // Amount of tokens
        uint tokenAmount = n_tokensToBuy; 

        // To be sure we have enough tokens to do the operation
        require(token.balanceOf(address(this)) >= tokenAmount); 

        // Transfer tokens to the user
        token.transfer(msg.sender, tokenAmount);

        // Emit an event
        emit TokensBought(msg.sender, address(token), tokenAmount, rate);
    }

    function sellTokens(uint _amount, uint _etherToRedeem) public {
        // Users can't sell more tokens than they have
        require(token.balanceOf(msg.sender) >= _amount);

        // Calculate the amount of Ether to redeem
        uint etherAmount = _etherToRedeem;

        // To be sure we have enough Ether to do the operation
        require(address(this).balance >= etherAmount); 

        // Perform sale
        token.transferFrom(msg.sender, address(this), _amount);
        msg.sender.transfer(etherAmount);

        emit TokensSold(msg.sender, address(token), _amount, rate);
    }

}