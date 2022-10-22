//SPDX-License-Identifier:MIT
pragma solidity ^0.8.9;

contract StreamFactory{

    IERC20 public token;

    struct Stream{
        address sender;
        address receiver;
        uint256 amount;
        uint256 startTime;
        uint256 stopTime;
        uint256 interval;
        uint256 remainingBalance;
        bool isEntity;
    }

    struct LoanVault{
        address tokenAddress;
        uint256 totalBalance;
    }
    
    event StreamCreated(address indexed sender, address indexed receiver, uint256 amount, uint256 startTime, uint256 stopTime, uint256 interval);
    event withdraw(address indexed sender, address indexed receiver, uint256 amount);
    

    mapping(address => mapping(address => Stream)) public streams;
    mapping(address => LoanVault) public loanVaults;
    mapping(address => uint256) public shares;

    function createStream(address sender, address receiver, uint256 amount, uint256 startTime, uint256 stopTime, uint256 interval, address tokenAddress) public {
        require(startTime < stopTime, "Start time must be before stop time");
        require(interval > 0, "Interval must be greater than 0");
        require(amount > 0, "Amount must be greater than 0");
        require(receiver != msg.sender, "Sender and receiver must be different");
        require(streams[msg.sender][receiver].isEntity == false, "Stream already exists");

        token = IERC20(tokenAddress);

        streams[msg.sender][receiver] = Stream(msg.sender, receiver, amount, startTime, stopTime, interval, amount, true);
        token.transferFrom(msg.sender, address(this), amount);

        emit StreamCreated(msg.sender, receiver, amount, startTime, stopTime, interval);
    }

    function getStream(address sender, address receiver) public view returns (Stream memory){
        return streams[sender][receiver];
    }

    function getStreamBalance(address sender, address receiver) public view returns(uint256){
        Stream memory stream = streams[sender][receiver];
        require(stream.isEntity == true, "Stream does not exist");
        require(stream.remainingBalance > 0, "Stream is empty");
        require(stream.receiver == msg.sender, "Only receiver can withdraw from stream");

        uint256 elapsedTime = block.timestamp - stream.startTime;
        uint256 totalIntervalCount = (stream.stopTime - stream.startTime) / stream.interval;
        uint256 withdrawnIntervalCount = elapsedTime / stream.interval;
        uint256 amountPerInterval = stream.amount / totalIntervalCount;
        if(withdrawnIntervalCount > totalIntervalCount){
            uint256 amountToWithdraw = amountPerInterval * totalIntervalCount;
            return amountToWithdraw;
        }else{
            uint256 amountToWithdraw = amountPerInterval * withdrawnIntervalCount;
            return amountToWithdraw;
        }
    }

    function withdrawFromStream(address sender, address receiver) public {
        Stream memory stream = streams[sender][receiver];
        require(stream.isEntity == true, "Stream does not exist");
        require(stream.remainingBalance > 0, "Stream is empty");
        require(stream.receiver == msg.sender, "Only receiver can withdraw from stream");

        uint256 elapsedTime = block.timestamp - stream.startTime;
        uint256 totalIntervalCount = (stream.stopTime - stream.startTime) / stream.interval;
        uint256 withdrawnIntervalCount = elapsedTime / stream.interval;

        uint256 amountPerInterval = stream.amount / totalIntervalCount;

        if(withdrawnIntervalCount > totalIntervalCount){
            uint256 amountToWithdraw = amountPerInterval * totalIntervalCount;
            stream.remainingBalance -= amountToWithdraw;
            streams[sender][receiver] = stream;
            token.transferFrom(address(this),msg.sender,amountToWithdraw);
            emit withdraw(sender, receiver, amountToWithdraw);
        }else{
            uint256 amountToWithdraw = amountPerInterval * withdrawnIntervalCount;
            stream.remainingBalance -= amountToWithdraw;
            streams[sender][receiver] = stream;
            token.transferFrom(address(this),msg.sender,amountToWithdraw);
            emit withdraw(sender, receiver, amountToWithdraw);
        }

        //require(amountToWithdraw <= stream.remainingBalance, "Stream is empty");

    }

    function cancelStream(address sender, address receiver) public {
        Stream memory stream = streams[sender][receiver];
        require(stream.isEntity == true, "Stream does not exist");
        require(stream.sender == msg.sender, "Only sender can cancel stream");

        streams[sender][receiver].isEntity = false;
        payable(stream.sender).transfer(stream.remainingBalance);
    }


    function forwardFunds(address sender, address receiver, uint256 amount) public {
        require(streams[sender][receiver].isEntity == true, "Stream does not exist");
        require(streams[sender][receiver].remainingBalance >= amount, "Stream does not have enough funds");
        require(streams[sender][receiver].sender == msg.sender, "Only sender can forward funds");

        streams[sender][receiver].remainingBalance -= amount;
        payable(streams[sender][receiver].receiver).transfer(amount);
    }

    //Loan functions

    function supplyLiquidity(address tokenAddress, uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(tokenAddress != address(0), "Token address must be provided");
        loanVaults[tokenAddress].tokenAddress = tokenAddress;
        loanVaults[tokenAddress].totalBalance += amount;
        token.transfer(address(this), amount);
        shares[msg.sender] += (amount*100)/loanVaults[tokenAddress].totalBalance;
    }

    function borrow(address tokenAddress, uint256 amount, address sender) public {
        require(amount > 0, "Amount must be greater than 0");
        require(tokenAddress != address(0), "Token address must be provided");
        require(loanVaults[tokenAddress].totalBalance >= amount, "Not enough liquidity");
        require(streams[sender][msg.sender].remainingBalance >= amount, "Stream does not have enough funds");
        token.transferFrom(address(this), msg.sender, amount);
        loanVaults[tokenAddress].totalBalance -= amount;
        streams[sender][msg.sender].amount-=amount;
        createStream(sender, address(this), amount, block.timestamp, streams[sender][msg.sender].stopTime, streams[sender][msg.sender].interval, tokenAddress);
    }

    function removeLiquidity(address tokenAddress, uint256 share) public {
        require(share > 0, "share must be greater than 0");
        require(tokenAddress != address(0), "Token address must be provided");
        require(shares[msg.sender] >= share, "Not enough share");
        require(loanVaults[tokenAddress].totalBalance > 0, "No liquidity");
        uint256 amount = (share*loanVaults[tokenAddress].totalBalance)/100;
        require(amount <= loanVaults[tokenAddress].totalBalance, "Not enough liquidity");
        loanVaults[tokenAddress].totalBalance -= amount;
        shares[msg.sender] -= share;
        token.transferFrom(address(this), msg.sender, amount);
    }

    function getVaultBalance(address tokenAddress) public view returns (uint256){
        return loanVaults[tokenAddress].totalBalance;
    }

}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
}