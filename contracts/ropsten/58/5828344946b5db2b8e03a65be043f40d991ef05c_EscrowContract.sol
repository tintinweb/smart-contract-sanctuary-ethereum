/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: UNLICENSED

interface IERC20 {
       function totalSupply() external view returns (uint256);
       function balanceOf(address account) external view returns (uint256);
       function transfer(address recipient, uint256 amount) external returns (bool);
       function allowance(address owner, address spender) external view returns (uint256);
       function approve(address spender, uint256 amount) external returns (bool);
       function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
       event Transfer(address indexed from, address indexed to, uint256 value);
       event Approval(address indexed owner, address indexed spender, uint256 value);
   }



contract EscrowContract {
    
    enum Status{ NEUTRAL, CONFIRM, CANCEL }
    
    struct Deal{
        address payable seller;
        address payable customer;
        uint256 amount;
        Status seller_status;
        Status customer_status;
        Status escrow_agent_status;
        Status deal_status;
    }
    
    event DealCreated(bytes32 _deal_id);
    event DealConfirmed(bytes32 _deal_id);
    event DealCanceled(bytes32 _deal_id);
            
    mapping (bytes32 => Deal) public deals;
    mapping (bytes32 => bool) is_id_taken;
    address escrow;
    IERC20 usdt = IERC20(0x6EE856Ae55B6E1A249f04cd3b947141bc146273c);
    
    constructor(address escrow_agent){
        escrow = escrow_agent;
    }
    
    function getDealStatus(Status _seller, Status _buyer, Status _escrow_agent) private pure returns(Status){
        Status deal_status = Status.NEUTRAL;
        if ((_seller == Status.CONFIRM && _buyer == Status.CONFIRM) || (_seller == Status.CONFIRM && _escrow_agent == Status.CONFIRM) || (_buyer == Status.CONFIRM && _escrow_agent == Status.CONFIRM))
        deal_status = Status.CONFIRM;
        else if ((_seller == Status.CANCEL && _buyer == Status.CANCEL) || (_seller == Status.CANCEL && _escrow_agent == Status.CANCEL) || (_buyer == Status.CANCEL && _escrow_agent == Status.CANCEL))
        deal_status = Status.CANCEL;
        return deal_status;
    }
    
    function getDeal(bytes32 id) public view returns(Deal memory){
        Deal memory deal = deals[id];
        return deal;
    }
    
    function _confirmDeal(bytes32 id) private{
        deals[id].seller.transfer(deals[id].amount);
        deals[id].deal_status = Status.CONFIRM;
        emit DealConfirmed(id);
    }
    
    function _cancelDeal(bytes32 id) private{
        deals[id].customer.transfer(deals[id].amount);
        deals[id].deal_status = Status.CANCEL;
        emit DealConfirmed(id);
    }
    
    function _checkDealStatus(bytes32 id) private{
        Status current_deal_status = getDealStatus(deals[id].seller_status, deals[id].customer_status, deals[id].escrow_agent_status);
        if (current_deal_status == Status.CONFIRM) _confirmDeal(id);
        else if (current_deal_status == Status.CANCEL) _cancelDeal(id);
        
    }
    
    function createDeal(address payable seller) payable external returns(bytes32){
        Deal memory new_deal = Deal({
            seller: seller,
            customer: payable(msg.sender),
            amount: msg.value,
            seller_status: Status.NEUTRAL,
            customer_status: Status.NEUTRAL,
            escrow_agent_status: Status.NEUTRAL,
            deal_status: Status.NEUTRAL
        });
        uint32 hash = 0;
        bytes32 new_deal_id = keccak256(abi.encode(seller, msg.sender, msg.value, hash));
        while (is_id_taken[new_deal_id]){
            hash += 1;
            new_deal_id = keccak256(abi.encode(seller, msg.sender, msg.value, hash));
        }
        
        deals[new_deal_id] = new_deal;
        is_id_taken[new_deal_id] = true;
        
        emit DealCreated(new_deal_id);
        return new_deal_id;
        
    }
    
    function confirmDeal(bytes32 id) external{
        require( deals[id].deal_status == Status.NEUTRAL, "Deal is closed");
        if (msg.sender == deals[id].seller) deals[id].seller_status = Status.CONFIRM;
        else if (msg.sender == deals[id].customer) deals[id].customer_status = Status.CONFIRM;
        else if (msg.sender == escrow) deals[id].escrow_agent_status = Status.CONFIRM;
        else revert("Not permitted");
        _checkDealStatus(id);
    }
    
    function cancelDeal(bytes32 id) external{
        require( deals[id].deal_status == Status.NEUTRAL, "Deal is closed");
        if (msg.sender == deals[id].seller) deals[id].seller_status = Status.CANCEL;
        else if (msg.sender == deals[id].customer) deals[id].customer_status = Status.CANCEL;
        else if (msg.sender == escrow) deals[id].escrow_agent_status = Status.CANCEL;
        else revert("Not permitted");
        _checkDealStatus(id);
    }
    
    
}