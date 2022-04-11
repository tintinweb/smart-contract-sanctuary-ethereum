pragma solidity ^0.4.17;
import './Reserve.sol';
import './TestToken.sol';
contract Exchange {

    address private owner;
    //token => reserve
    mapping(address => address) supportToken;

    function() external payable { }

    function Exchange() public{
        owner = msg.sender;
    }

    function addReserve(address reserve, address token) public {
        require(msg.sender == owner);
        require(reserve != address(0) && token != address(0));
        supportToken[token] = reserve;
    }
    function removeReserve(address reserve, address token) public {
        require(msg.sender == owner);
        require(reserve != address(0) && token != address(0));
        delete supportToken[token];
    }

    function getExchangeRate(address srcToken,address destToken,uint srcAmount) public view returns (uint) {
        require(srcToken != address(0) && destToken != address(0));
        require(supportToken[srcToken] != address(0) && supportToken[destToken] != address(0));
        Reserve srcReserve = Reserve(supportToken[srcToken]);
        Reserve destReserve = Reserve(supportToken[destToken]);

        uint sellRateSrc = srcReserve.getExchangeRate(false,srcAmount);
        uint rt = destReserve.getExchangeRate(true,sellRateSrc);
        return rt;
    }

    function exchange(address srcToken,address destToken,uint srcAmount) public payable{
        require(srcToken != destToken);
        require(srcToken != address(0) && destToken != address(0));
        TestToken t1 = TestToken(srcToken);
        TestToken t2 = TestToken(destToken);
        Reserve srcReserve = Reserve(supportToken[srcToken]);
        Reserve destReserve = Reserve(supportToken[destToken]);

        require(t1.balanceOf(msg.sender) >= srcAmount);
        uint allowanceT1 = t1.allowance(msg.sender, this);
        require(allowanceT1 >= srcAmount);

        t1.transferFrom(msg.sender,this,srcAmount);
        t1.approve(supportToken[srcToken],srcAmount);
        srcReserve.sell(srcAmount);
       
        uint receiveEther = srcReserve.getExchangeRate(false, srcAmount);

        destReserve.buy.value(receiveEther)();

        uint receiveToken = destReserve.getExchangeRate(true, receiveEther);
        t2.transfer(msg.sender, receiveToken);
    }
}