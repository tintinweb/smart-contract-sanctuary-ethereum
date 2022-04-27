/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

pragma solidity ^0.4.13;

// Wallet Controller v1.2
// UserWallet 수정 : ETH 입금 시 이벤트 발생

contract AbstractSweeper {
    function sweep(address token, uint amount) returns (bool);

    function () { revert(); }

    Controller controller;

    function AbstractSweeper(address _controller) {
        controller = Controller(_controller);
    }

    modifier canSweep() {
        if (msg.sender != controller.owner()) revert();
        if (controller.halted()) revert();
        _;
    }
}

contract Token {
    function balanceOf(address a) returns (uint) {
        (a);
        return 0;
    }

    function transfer(address a, uint val) returns (bool) {
        (a);
        (val);
        return false;
    }
}

contract DefaultSweeper is AbstractSweeper {
    function DefaultSweeper(address controller)
    AbstractSweeper(controller) {}

    function sweep(address _token, uint _amount) canSweep returns (bool) {
        bool success = false;
        address destination = controller.destination();
        //        address destination = controller.sweeperOf(_token);

        if (_token != address(0)) {
            Token token = Token(_token);
            uint amount = _amount;
            if (amount > token.balanceOf(this)) {
                return false;
            }

            success = token.transfer(destination, amount);
        }
        else {
            uint amountInWei = _amount;
            if (amountInWei > this.balance) {
                return false;
            }

            success = destination.send(amountInWei);
        }

        if (success) {
            controller.logSweep(this, destination, _token, _amount);
        }
        return success;
    }
}

contract UserWallet {
    AbstractSweeperList sweeperList;

    event MkwEthReceived(address from, uint256 amount, bytes data);

    function UserWallet(address _sweeperlist) {
        sweeperList = AbstractSweeperList(_sweeperlist);
    }

    function () public payable {
        MkwEthReceived(msg.sender, msg.value, msg.data);
    }

    function tokenFallback(address _from, uint _value, bytes _data) {
        (_from);
        (_value);
        (_data);
     }

    function sweep(address _token, uint _amount) returns (bool) {
        (_amount);
        return sweeperList.sweeperOf(_token).delegatecall(msg.data);
    }
}

contract AbstractSweeperList {
    function sweeperOf(address _token) constant public returns (address);
}

contract Controller is AbstractSweeperList {

    address public owner;
    address public walletMaker;
    address public destination;

    bool public halted;

    event LogNewWallet(address receiver);
    event LogSweep(address indexed from, address indexed to, address indexed token, uint amount);
    event LogSweeperOf(address token, address sweeper);

    modifier onlyOwner() {
        if (msg.sender != owner) revert();
        _;
    }

    modifier onlyWalletMaker() {
        require(msg.sender == owner || msg.sender == walletMaker);
        _;
    }

    function Controller() {
        owner = msg.sender;
        walletMaker = msg.sender;
        destination = msg.sender;
    }

    function changeWalletMaker(address _newMaker) onlyOwner {
        walletMaker = _newMaker;
    }

    function changeDestination(address _dest) onlyOwner {
        destination = _dest;
    }

    function changeOwner(address _owner) onlyOwner {
        owner = _owner;
    }

    function makeWallet() onlyWalletMaker returns (address wallet)  {
        wallet = address(new UserWallet(this));
        LogNewWallet(wallet);
    }

    function halt() onlyOwner {
        halted = true;
    }

    function start() onlyOwner {
        halted = false;
    }

    address public defaultSweeper = address(new DefaultSweeper(this));
    mapping (address => address) sweepers;

    function sweeperOf(address _token) constant public returns (address) {
        address sweeper = sweepers[_token];
        if (sweeper == 0) sweeper = defaultSweeper;
        return sweeper;
    }

    function logSweep(address from, address to, address token, uint amount) {
        LogSweep(from, to, token, amount);
    }
}