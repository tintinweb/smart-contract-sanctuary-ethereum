// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Pausable.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./Counters.sol";

contract MixerContract is Pausable, Ownable {
    using Counters for Counters.Counter;

    IERC20 private GR;
    IERC20 private USDT;
    IERC20 private TON;

    uint256 ID_GR = 1;
    uint256 ID_USDT = 2;
    uint256 ID_TON = 3;

    Counters.Counter private _investCounter;

    struct Invest {
        address wallet;
        uint256 amount;
        uint256 percent;
        uint256 rewardDate;
        uint256 coinId;
    }

    struct CoinUserData {
        uint256 coinId;
        uint256 amount;
    }

    mapping(uint256 => uint256) private percents;
    mapping(uint256 => Invest) private invests;
    mapping(address => uint256) private userBalanceGR;
    mapping(address => uint256) private userBalanceUSDT;
    mapping(address => uint256) private userBalanceTON;

    constructor(
        IERC20 grContract,
        IERC20 usdtContract,
        IERC20 tonContract
    ) {
        GR = grContract;
        USDT = usdtContract;
        TON = tonContract;

        percents[ID_GR] = 1;
        percents[ID_USDT] = 1;
        percents[ID_TON] = 1;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function inputToken(uint256 coinId) public payable {
        uint256 _amount = msg.value;

        bool sent = false;

        if (coinId == ID_GR) {
            uint256 allowance = GR.allowance(_msgSender(), address(this));
            require(allowance >= _amount, "Check the token allowance");
            sent = GR.transferFrom(_msgSender(), address(this), _amount);

            require(sent, "Failed to send");
            userBalanceGR[_msgSender()] += _amount;
        } else if (coinId == ID_USDT) {
            uint256 allowance = USDT.allowance(_msgSender(), address(this));
            require(allowance >= _amount, "Check the token allowance");
            sent = USDT.transferFrom(_msgSender(), address(this), _amount);

            require(sent, "Failed to send");
            userBalanceUSDT[_msgSender()] += _amount;
        } else if (coinId == ID_TON) {
            uint256 allowance = USDT.allowance(_msgSender(), address(this));
            require(allowance >= _amount, "Check the token allowance");
            sent = USDT.transferFrom(_msgSender(), address(this), _amount);

            require(sent, "Failed to send");
            userBalanceTON[_msgSender()] += _amount;
        }
    }

    function withdrawal(
        address _address,
        uint256 coinIdSend,
        uint256 amountSend,
        uint256 coinIdBalance,
        uint256 amountBalance
    ) public onlyOwner {
        uint256 balance = 0;
        if (coinIdBalance == ID_GR) {
            balance = userBalanceGR[_address];
        } else if (coinIdBalance == ID_USDT) {
            balance = userBalanceUSDT[_address];
        } else if (coinIdBalance == ID_TON) {
            balance = userBalanceTON[_address];
        }
        require(balance >= amountBalance, "Not enough balance");
        require(
            coinIdSend == ID_GR ||
            coinIdSend == ID_USDT ||
            coinIdSend == ID_TON,
            "This coin not supported yet"
        );

        bool sent = false;

        if (coinIdSend == ID_GR) {
            sent = GR.transferFrom(address(this), _address, amountSend);
            require(sent, "Failed to send");
            userBalanceGR[_address] -= amountBalance;
        } else if (coinIdSend == ID_USDT) {
            sent = USDT.transferFrom(address(this), _address, amountSend);
            require(sent, "Failed to send");

            userBalanceUSDT[_address] -= amountBalance;
        } else if (coinIdSend == ID_TON) {
            sent = TON.transferFrom(address(this), _address, amountSend);
            userBalanceTON[_address] -= amountBalance;
        }
    }

    function investGR(uint256 investId, uint256 _amount) public virtual {
        uint256 allowance = GR.allowance(_msgSender(), address(this));
        require(allowance >= _amount, "Check the token allowance");

        bool sent = GR.transferFrom(_msgSender(), address(this), _amount);
        require(sent, "Failed to send GR");
        _investCounter.increment();
        invests[investId] = Invest(
            _msgSender(),
            _amount,
            percents[ID_GR],
            block.timestamp + 2678400,
            ID_GR
        );
    }

    function reward() public onlyOwner {
        uint256 investCounter = _investCounter.current();

        for (uint256 i = 0; i <= investCounter; i++) {
            if (
                invests[i].rewardDate > 1660000000 &&
                block.timestamp >= invests[i].rewardDate &&
                invests[i].amount > 0 &&
                invests[i].percent > 0
            ) {
                uint256 _reward = invests[i].amount *
                (100 / invests[i].percent);
                if (invests[i].coinId == ID_GR) {
                    uint256 balance = GR.balanceOf(address(this));
                    require(balance > 0, "Not enough balance");
                    GR.transfer(owner(), _reward);
                } else if (invests[i].coinId == ID_USDT) {
                    uint256 balance = USDT.balanceOf(address(this));
                    require(balance > 0, "Not enough balance");
                    USDT.transfer(owner(), _reward);
                }
            }
        }
    }

    function withdrawEth() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawGR() external onlyOwner {
        uint256 balance = GR.balanceOf(address(this));
        require(balance > 0, "GROption: amount sent is not correct");

        GR.transfer(owner(), balance);
    }

    function withdrawUSDT() external onlyOwner {
        uint256 balance = USDT.balanceOf(address(this));
        require(balance > 0, "GROption: amount sent is not correct");

        USDT.transfer(owner(), balance);
    }

    function withdrawTON() external onlyOwner {
        uint256 balance = TON.balanceOf(address(this));
        require(balance > 0, "GROption: amount sent is not correct");

        TON.transfer(owner(), balance);
    }
}