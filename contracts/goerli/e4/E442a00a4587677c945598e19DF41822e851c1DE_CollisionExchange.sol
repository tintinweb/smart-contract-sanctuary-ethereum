pragma solidity ^0.8.4;

contract  OrderBook {
    uint public amount;
    address public trader;

    event TradePosted(address,uint256);

    function postTrade(address _trader, uint _amount) external {
        amount = _amount;
        trader = _trader;
        emit TradePosted(_trader, _amount);
    }

    function getTrade() external view returns(address,uint256) {
        return (trader, amount);
    }
}

contract CollisionExchange {
    address public orderBook;
    address public owner;

    mapping(address => uint) public balances;

    constructor(address _orderBook) payable {
        orderBook = _orderBook;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender==owner);
        _;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount, address recepient) external  {
        require(balances[msg.sender] <= amount);
        require(recepient == msg.sender);
        balances[msg.sender] -= amount;
        (payable(msg.sender)).transfer(amount);
    } 

    function emergencyWithdraw() external payable onlyOwner {
        (payable(msg.sender)).transfer(address(this).balance);
    }

    function postTrade(uint _amount) external  {
        orderBook.delegatecall(abi.encodeWithSignature("postTrade(address,uint256)", msg.sender, _amount));
    }

    function setNewOwner(address _owner) external onlyOwner {
        require(_owner != address(0));
        owner = _owner;
    }

}