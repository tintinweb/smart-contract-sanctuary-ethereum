/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract Faucet {
    address public admin;
    address public token;
    uint256 public amount;

    uint256 constant maxTime = 3;

    mapping(address => uint256) times;

    constructor(address _token, uint256 _amount) {
        admin = msg.sender;
        token = _token;
        amount = _amount;
    }

    event Claim(address);
    event Withdraw(uint256);
    event SetAmount(uint256);

    function claim() public {
        require(msg.sender.code.length == 0);
        require(times[msg.sender] < maxTime);
        times[msg.sender]++;
        IERC20(token).transfer(msg.sender, amount);
        emit Claim(msg.sender);
    }

    function withdraw(uint256 amount) public {
        require(msg.sender == admin);
        IERC20(token).transfer(msg.sender, amount);
        emit Withdraw(amount);
    }

    function setAmount(uint256 _amount) public {
        require(msg.sender == admin);
        amount = _amount;
        emit SetAmount(amount);
    }
}