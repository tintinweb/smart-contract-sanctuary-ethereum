/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface erc20 {
    function approve(address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
}

interface cy20 {
    function redeemUnderlying(uint) external returns (uint);
    function mint(uint) external returns (uint);
    function borrow(uint) external returns (uint);
    function repayBorrow(uint) external returns (uint);
}

interface registry {
    function cy(address) external view returns (address);
    function price(address) external view returns (uint);
}

interface cl {
    function latestAnswer() external view returns (int);
}

contract ib_amm {
    address constant mim = address(0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3);
    address constant dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    registry constant ff = registry(0x5C08bC10F45468F18CbDC65454Cbd1dd2cB1Ac65);
    cl constant dai_feed = cl(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9);
    cl constant mim_feed = cl(0x7A364e8770418566e3eb2001A96116E6138Eb32F);
    
    address public governance;
    address public pending_governance;
    bool public breaker = false;
    int public threshold = 99000000;
    uint constant public fee = 3;
    uint constant public base = 1000;
    
    constructor(address _governance) {
        governance = _governance;
    }

    modifier only_governance() {
        require(msg.sender == governance);
        _;
    }

    function set_governance(address _governance) external only_governance {
        pending_governance = _governance;
    }

    function accept_governance() external {
        require(msg.sender == pending_governance);
        governance = pending_governance;
    }

    function set_breaker(bool _breaker) external only_governance {
        breaker = _breaker;
    }

    function set_threshold(int _threshold) external only_governance {
        threshold = _threshold;
    }

    function repay(cy20 cy, address token, uint amount) external returns (bool) {
         _safeTransferFrom(token, msg.sender, address(this), amount);
        erc20(token).approve(address(cy), amount);
        require(cy.repayBorrow(amount) == 0, "ib: !repay");
        return true;
    }

    function dai_quote() external view returns (int) {
        return dai_feed.latestAnswer();
    }

    function mim_quote() external view returns (int) {
        return mim_feed.latestAnswer();
    }

    function buy_quote(address to, uint amount) public view returns (uint) {
        uint _fee = amount * fee / base;
        return (amount - _fee)  * 1e18 / ff.price(to);
    }

    function sell_quote(address from, uint amount) public view returns (uint) {
        uint _fee = amount * fee / base;
        return (amount - _fee) * ff.price(from) / 1e18;
    }
    
    function buy(address to, uint amount, uint minOut) external returns (bool) {
        require(!breaker, "breaker");
        require(dai_feed.latestAnswer() > threshold, "peg");
        _safeTransferFrom(dai, msg.sender, governance, amount);
        uint _quote = buy_quote(to, amount);
        require(_quote > 0 && _quote >= minOut, "< minOut");
        require(cy20(ff.cy(to)).borrow(_quote) == 0, "ib: borrow failed");
        _safeTransfer(to, msg.sender, _quote);
        return true;
    }
    
    function sell(address from, uint amount, uint minOut) external returns (bool) {
        require(!breaker, "breaker");
        require(mim_feed.latestAnswer() > threshold, "peg");
        _safeTransferFrom(from, msg.sender, governance, amount);
        uint _quote = sell_quote(from, amount);
        require(_quote > 0 && _quote >= minOut, "< minOut");
        _safeTransfer(mim, msg.sender, _quote);
        return true;
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}