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

    mapping(uint256 => uint256) private rewardPercents;
    mapping(uint256 => uint256) private commissionPercents;
    mapping(uint256 => Invest) private invests;

    constructor(
        IERC20 grContract,
        IERC20 usdtContract,
        IERC20 tonContract
    ) {
        GR = grContract;
        USDT = usdtContract;
        TON = tonContract;

        rewardPercents[ID_GR] = 1;
        rewardPercents[ID_USDT] = 1;
        rewardPercents[ID_TON] = 1;

        commissionPercents[ID_GR] = 1;
        commissionPercents[ID_USDT] = 1;
        commissionPercents[ID_TON] = 1;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function inputToken(uint256 coinId) public payable {
        require(
            coinId == ID_GR ||
            coinId == ID_USDT ||
            coinId == ID_TON,
            "This coin not supported yet"
        );
        uint256 _amount = msg.value;

        bool sent = false;

        if (coinId == ID_GR) {
            uint256 allowance = GR.allowance(_msgSender(), address(this));
            require(allowance >= _amount, "Check the token allowance");
            sent = GR.transferFrom(_msgSender(), address(this), _amount);
            require(sent, "Failed to send");
        } else if (coinId == ID_USDT) {
            uint256 allowance = USDT.allowance(_msgSender(), address(this));
            require(allowance >= _amount, "Check the token allowance");
            sent = USDT.transferFrom(_msgSender(), address(this), _amount);
            require(sent, "Failed to send");
        } else if (coinId == ID_TON) {
            uint256 allowance = TON.allowance(_msgSender(), address(this));
            require(allowance >= _amount, "Check the token allowance");
            sent = TON.transferFrom(_msgSender(), address(this), _amount);
            require(sent, "Failed to send");
        }
    }

    function withdrawal(
        address _address,
        uint256 coinId,
        uint256 amount
    ) public onlyOwner {
        require(
            coinId == ID_GR ||
            coinId == ID_USDT ||
            coinId == ID_TON,
            "This coin not supported yet"
        );

        bool sent = false;

        if (coinId == ID_GR) {
            sent = GR.transferFrom(address(this), _address, amount);
            require(sent, "Failed to send");
        } else if (coinId == ID_USDT) {
            sent = USDT.transferFrom(address(this), _address, amount);
            require(sent, "Failed to send");
        } else if (coinId == ID_TON) {
            sent = TON.transferFrom(address(this), _address, amount);
            require(sent, "Failed to send");
        }
    }

    function investGR(uint256 investId) public payable {
        require(rewardPercents[ID_GR] > 0, "Disabled");
        uint256 _amount = msg.value;
        uint256 allowance = GR.allowance(_msgSender(), address(this));
        require(allowance >= _amount, "Check the token allowance");

        bool sent = GR.transferFrom(_msgSender(), address(this), _amount);
        require(sent, "Failed to send GR");
        _investCounter.increment();
        invests[investId] = Invest(
            _msgSender(),
            _amount,
            rewardPercents[ID_GR],
            block.timestamp + 2678400,
            ID_GR
        );
    }

    function withdrawalInvest(
        uint256 investId,
        uint256 amount
    ) public {
        require(invests[investId].wallet == _msgSender(), "Not owner");
        require(invests[investId].amount >= amount, "Not enough amount");

        bool sent = false;

        if (invests[investId].coinId == ID_GR) {
            sent = GR.transfer(_msgSender(), amount);
            require(sent, "Failed to send");
            invests[investId].amount -= amount;
        } else if (invests[investId].coinId == ID_USDT) {
            sent = USDT.transfer(_msgSender(), amount);
            require(sent, "Failed to send");
            invests[investId].amount -= amount;
        } else if (invests[investId].coinId == ID_TON) {
            sent = TON.transfer(_msgSender(), amount);
            require(sent, "Failed to send");
            invests[investId].amount -= amount;
        }
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
                    GR.transfer(invests[i].wallet, _reward);
                } else if (invests[i].coinId == ID_USDT) {
                    uint256 balance = USDT.balanceOf(address(this));
                    require(balance > 0, "Not enough balance");
                    USDT.transfer(invests[i].wallet, _reward);
                } else if (invests[i].coinId == ID_TON) {
                    uint256 balance = TON.balanceOf(address(this));
                    require(balance > 0, "Not enough balance");
                    TON.transfer(invests[i].wallet, _reward);
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