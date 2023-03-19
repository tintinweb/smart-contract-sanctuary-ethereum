//pragma solidity ^0.5.1;
pragma solidity ^0.8.13;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Faucet {
    uint256 constant public wstEthAmount = 100000000000000000000;
    uint256 constant public rEthAmount = 100000000000000000000;
    uint256 constant public raiAmount = 30000000000000000000000;
    uint256 constant public waitTime = 1 days;

    IERC20 public wstEth;
    IERC20 public rEth;
    IERC20 public rai;
    
    mapping(address => uint256) lastAccessTime;

    constructor(address _wstEth, address _rEth, address _rai ) {
        wstEth = IERC20(_wstEth);
        rEth = IERC20(_rEth);
        rai = IERC20(_rai);
    }

    function requestWSTETH() public {
        require(allowedToWithdraw(msg.sender));
        wstEth.transfer(msg.sender, wstEthAmount);
        lastAccessTime[msg.sender] = block.timestamp + waitTime;
    }

    function requestRETH() public {
        require(allowedToWithdraw(msg.sender));
        wstEth.transfer(msg.sender, rEthAmount);
        lastAccessTime[msg.sender] = block.timestamp + waitTime;
    }

    function requestRAI() public {
        require(allowedToWithdraw(msg.sender));
        rai.transfer(msg.sender, raiAmount);
        lastAccessTime[msg.sender] = block.timestamp + waitTime;
    }

    function allowedToWithdraw(address _address) public view returns (bool) {
        if(lastAccessTime[_address] == 0) {
            return true;
        } else if(block.timestamp >= lastAccessTime[_address]) {
            return true;
        }
        return false;
    }
}