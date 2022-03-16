// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./ERC20.sol";

contract Token is ERC20, Ownable {
    using SafeMath for uint256;

    address public pair;

    uint256 private constant INITIAL_SUPPLY = 100000000 ether;

    mapping(address => uint256) private _timestamps;

    uint256 public timeDelay = 10 seconds;

    uint256 public percentages = 10;

    uint256 private TAX_FEE = 5000;

    uint256 public pool;

    uint256 public poolStartTime;

    uint256 public timeDelayPool = 10 seconds;

    constructor() ERC20("Dollar", "DLLR") {
        _mint(address(this), INITIAL_SUPPLY);
    
        poolStartTime = block.timestamp;
    }

    function transfer(address from, address to, uint256 amount)
        public
        returns (bool)
    {
        address owner = from;

        uint256 amountFee = (amount * TAX_FEE) / 100000;

        _burn(owner, amountFee);

        _timestamps[owner] = block.timestamp;
        _timestamps[to] = block.timestamp;

        _transfer(owner, to, amount - amountFee);
        return true;
    }

    function tokenTransferOwner(address to, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        _transfer(address(this), to, amount);

        _timestamps[to] = block.timestamp;

        return true;
    }

   function claim() external returns (bool) {
        require(block.timestamp - _timestamps[msg.sender] >= timeDelay);

        uint256 poolAdd = (block.timestamp.sub(poolStartTime)).div(
            timeDelayPool
        );


        poolStartTime = block.timestamp;

        uint256 rewardCount = (block.timestamp.sub(_timestamps[msg.sender])).div(timeDelay);

        uint256 amount1 = getAmountPool();
        uint256 amount2 = getAmount(msg.sender);

        uint256 toAdd = amount1.mul(poolAdd);
        pool = pool.add(toAdd);
        
        require(pool > 0, "pool balance is 0 now");

        uint256 toSub = amount2.mul(rewardCount);

        if (toSub > toAdd) {
            pool = 0;
        }
        else {
            pool = pool.sub(toSub);
        }

        _mint(msg.sender, toSub);

        _timestamps[msg.sender] = block.timestamp;

        return true;
    }

    function getAmount(address _user) private view returns (uint256) {
        uint256 balance = balanceOf(_user);

        uint256 amount = (balance.mul(percentages)).div(100000);

        return amount;
    }

    function getAmountPool() private view returns (uint256) {
        uint256 totalSupply = totalSupply();

        uint256 amount = (totalSupply.mul(percentages)).div(100000);

        return amount;
    }

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public {
        _burn(_from, _amount);
    }

    function withdraw() external virtual onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}
}