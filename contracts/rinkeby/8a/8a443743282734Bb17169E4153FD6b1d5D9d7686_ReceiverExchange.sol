// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "./IEsterToken.sol";

contract ReceiverExchange {

    address esterToken;
    IEsterToken public EstrContract;
    // mapping(address => uint256) public balanceOf;
    event BoughtESTR(address indexed sender, uint256 amount);

    constructor(address _esterToken) {
        esterToken = _esterToken;
        EstrContract = IEsterToken(esterToken);
    }

    struct BuyOrder {
        uint256 amount;
        uint256 bidPrice;
        address userId;
    }



    function handleBatchOrders(BuyOrder[] memory batchBuyOrders) external {
        for (uint256 i = 0; i <= batchBuyOrders.length; i++) {
            BuyOrder memory buy_order = batchBuyOrders[i];
            _handleBuyOrderTransaction(buy_order);
        }
    }

    function _handleBuyOrderTransaction(BuyOrder memory buy_order) internal returns(bool) {
        require(buy_order.bidPrice >= 1 ether, "Bid price is too low!");
        _transferToBuyer(buy_order.userId, buy_order.amount);
        return true;
    }
   

    // change this to a internal function later
    function _transferToBuyer(address buyer, uint256 amount) public returns(bool) {
        // balanceOf[buyer] += amount;
        emit BoughtESTR(buyer, amount);
        return EstrContract.transfer(buyer, amount);
    }

    // Using EsterToken function transfer(address recipient, uint256 amount) public returns bool

    function contractBuyESTR() public {
        EstrContract.depositEth();
    }

    receive() external payable {

    }


}

// SPDX-License-Identifier:MIT
// interface for EsterToken

pragma solidity ^0.8.0;


interface IEsterToken {
    

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address from, address recipient, uint256 amount) external returns (bool);

    function depositEth() external payable;
    function withdrawEth(uint256 amount) external;

    event Transfer(address indexed _from, address indexed _to, uint256 amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 amount);
    event Deposit(address indexed sender, uint256 amount);
    event Withdrawal(address indexed recipient, uint256 amount);


}