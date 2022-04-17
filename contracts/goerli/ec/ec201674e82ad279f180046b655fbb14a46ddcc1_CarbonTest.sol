// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address owner) external view returns (uint);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

contract CarbonTest {

    event TestBalanceLog(uint256 balance);
    event TestAddressLog(address[] targets);
    event TestPayloadLog(bytes[] payload);

    address private immutable owner;
    IWETH private immutable WETH;

    function getOwner() external view returns (address) {
        return owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "sender not authorized.");
        _;
    }

    constructor(address _WETH9) public payable {
        WETH = IWETH(_WETH9);
        IWETH(_WETH9).deposit{value: msg.value}();
        owner = msg.sender;
    }

    receive() external payable {

    }

    function unwrapAndWithdraw() external onlyOwner payable {
        WETH.withdraw(WETH.balanceOf(address(this)));
        payable(owner).transfer(address(this).balance);
    }

    function trade(uint256 _wethAmountToFirstMarket, address[] memory _targets, bytes[] memory _payloads) external onlyOwner payable {
        emit TestBalanceLog(_wethAmountToFirstMarket);

        require (_targets.length == _payloads.length, "invalid targets");
        uint256 _wethBalanceBefore = WETH.balanceOf(address(this));
        
        emit TestBalanceLog(_wethBalanceBefore);
        emit TestAddressLog(_targets);
        emit TestPayloadLog(_payloads);
        
    }
}