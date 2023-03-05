/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

// Sources flattened with hardhat v2.12.7 https://hardhat.org

// File contracts/fwd.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Trade Entry - deploy contract for client post confirmation

contract fwd3 {
    address payable internal cpty_addr;
    address payable internal owner;
    address internal market_addr;

    uint internal strike;
    uint public notional;
    uint public cpty_amount;
    uint public owner_amount;
    uint public im;
    uint _trade_direction;

    constructor(
        address Cpty_Address,
        address Market_Address,
        uint USDINR_rate,
        uint Notional_USD,
        uint r_percent,
        uint trade_direction
    ) {
        _trade_direction = trade_direction;
        owner = payable(msg.sender);
        cpty_addr = payable(Cpty_Address);
        market_addr = Market_Address;
        strike = USDINR_rate;
        notional = Notional_USD;

        im = (notional * r_percent) / 100;

        cpty_amount = im;
        owner_amount = 0;
    }

    // Function modifiers

    // Only owner interaction function modifier

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    // Only buyer interaction function modifier

    modifier onlyBuyer() {
        require(msg.sender == cpty_addr, "not counterparty");
        _;
    }

    // Only market data interaction function modifier

    modifier onlyMarket() {
        require(msg.sender == market_addr, "not authorized");
        _;
    }

    // Variables

    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowed;

    // Events

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint transfer_value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint allowed_value
    );

    // Functions
    // Check trade-status

    function trade_status() public view returns (string memory) {
        if (address(this).balance < uint((notional * 5) / 100)) {
            return ("Trade Pending");
        } else {
            return ("Trade in Progress");
        }
    }

    // Get Contract Balance

    function balance() public view returns (uint) {
        return address(this).balance;
    }

    // Transaction function

    receive() external payable {}

    fallback() external payable {}

    uint internal b = 0;

    function deposit_margin() public payable returns (bool) {
        require(msg.sender == cpty_addr, "Not counterparty");
        // require(msg.value == im, "Enter exact IM");
        require(b == 0, "IM already locked"); // not full-proof logic

        if (msg.sender == cpty_addr) {
            require(b == 0, "IM already locked");
            b = b + 1;
        }

        address payable x = payable(msg.sender);
        x.call{gas: 30000, value: msg.value};
        emit Transfer(msg.sender, address(this), cpty_amount);

        return true;
    }

    // Update the market rate and calculate PnL - Market rate feeder can not transact

    int public CounterpartyPnL_USD;

    function updated_rate(uint _new_rate) public onlyMarket {
        if (_trade_direction == 1) {
            int _cpty_pnl = ((int(notional) *
                ((int(_new_rate) - int(strike)) * 1000000)) / int(strike)) /
                1000000;
            int(_cpty_pnl);
            CounterpartyPnL_USD = _cpty_pnl;
        } else {
            int _cpty_pnl = ((int(notional) *
                ((int(strike) - int(_new_rate)) * 1000000)) / int(strike)) /
                1000000;
            int(_cpty_pnl);
            CounterpartyPnL_USD = _cpty_pnl;
        }

        //BuyerPnL_USD = _buyer_pnl;

        if (CounterpartyPnL_USD > 0) {
            cpty_amount = im + uint(CounterpartyPnL_USD);
        } else {
            cpty_amount = im + uint(CounterpartyPnL_USD);
        }

        if (cpty_amount <= (im * 10) / 100 && cpty_amount >= 0) {
            payable(cpty_addr).transfer(cpty_amount); // txn fee borne by the Market Data updater
            emit Transfer(address(this), cpty_addr, cpty_amount);
            owner_amount = im - cpty_amount;

            payable(owner).transfer(owner_amount);
            emit Transfer(address(this), owner, owner_amount);
        }

        if (cpty_amount <= 0) {
            payable(owner).transfer(im);
            emit Transfer(address(this), owner, im);
        }
    }

    // Trade completion - initiated by buyer/seller

    function complete_trade() public payable returns (bool) {
        require(
            msg.sender == cpty_addr || msg.sender == owner,
            "Not Authorized"
        );
        if (cpty_amount > im) {
            payable(cpty_addr).transfer(im);
            emit Transfer(address(this), cpty_addr, im);
        } else {
            payable(cpty_addr).transfer(cpty_amount);
            emit Transfer(address(this), cpty_addr, cpty_amount);
            owner_amount = im - cpty_amount;

            payable(owner).transfer(owner_amount);
            emit Transfer(address(this), owner, owner_amount);
        }

        return true;
    }

    // Emergency liquidation - only owner initiation - *don't deposit ETH after emergency liquidation*

    function Emergency_Liquidation() public onlyOwner {
        payable(owner).transfer(address(this).balance);
        emit Transfer(address(this), owner, address(this).balance);
    }
}