/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract SwapA {
    using SafeMath for uint256;

    struct Investment {
        uint256 investId; // 活动id
        uint256 start; // 开始时间
        uint256 end; // 结束时间
        uint256 total; // 兑换总量
        uint256 sellTotal; // 当前已兑换总量
        uint256 maxAmount; // 单个用户可兑换总量
        uint256 minAmount; // 每次最低的购买量
        uint256 rate; // 兑换率
    }

    IERC20 public tokenERC20;
    address private _owner;
    uint256 public investLenght;
    //nonReentrant state
    bool private _locked = false;

    mapping(address => bool) private _whiteList;
    mapping(address => mapping(uint256 => uint256)) private _buyers;
    mapping(uint256 => Investment) private investments;

    //-------------------------------
    //------- Events ----------------
    //-------------------------------
    event Swap(
        address indexed sender,
        uint256 indexed investId,
        uint256 ethAmount,
        uint256 tokenAmount
    );
    event WithdrawEther(address indexed recipient, uint256 amount);
    event WithdrawToken(address indexed recipient, uint256 amount);
    event CreateInvest(uint256 indexed investId);
    event SetMaxAmount(uint256 indexed investId, uint256 amount);
    event SetMinAmount(uint256 indexed investId, uint256 amount);
    event SetRate(uint256 indexed investId, uint256 rate);
    //-------------------------------
    //------- Modifier --------------
    //-------------------------------
    modifier lock() {
        require(!_locked, "Reentrant call detected!");
        _locked = true;
        _;
        _locked = false;
    }
    modifier OnlyOwner() {
        require(address(msg.sender) == _owner, "NewSwap: access denied");
        _;
    }
    modifier investExists(uint256 _id) {
        require(_id < investLenght, "NewSwap: invest not exist!");
        _;
    }

    constructor(IERC20 tokenAddress) {
        tokenERC20 = tokenAddress;
        _owner = msg.sender;
    }

    //--------------------------------
    //-------  Internal Functions ----
    //--------------------------------
    function _isWhiteMember(address account) internal view returns (bool) {
        return _whiteList[account];
    }

    function _getUserBuyAmount(address account, uint256 _investId)
        internal
        view
        returns (uint256)
    {
        return _buyers[account][_investId];
    }

    function getTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

    //---------------------------------
    //-------- Onwer functions --------
    //---------------------------------

    function setMaxBuyAmount(uint256 _investId, uint256 _amount)
        external
        OnlyOwner
        investExists(_investId)
    {
        Investment storage invest_ = investments[_investId];
        invest_.maxAmount = _amount;
        emit SetMaxAmount(_investId, _amount);
    }

    function setMinBuyAmount(uint256 _investId, uint256 _amount)
        external
        OnlyOwner
        investExists(_investId)
    {
        Investment storage invest_ = investments[_investId];
        invest_.minAmount = _amount;
        emit SetMinAmount(_investId, _amount);
    }

    function setRate(uint256 _investId, uint256 rate)
        external
        OnlyOwner
        investExists(_investId)
    {
        Investment storage invest_ = investments[_investId];
        invest_.rate = rate;
        emit SetRate(_investId, rate);
    }

    function isWhiteMember(address account)
        external
        view
        OnlyOwner
        returns (bool)
    {
        return _isWhiteMember(account);
    }

    function getUserBuyAmount(address account, uint256 investId)
        external
        view
        returns (uint256)
    {
        return _getUserBuyAmount(account, investId);
    }

    function newInvestment(
        uint256 start,
        uint256 end,
        uint256 total,
        uint256 maxAmount,
        uint256 minAmount,
        uint256 rate
    ) external OnlyOwner {
        uint256 investId = investLenght++;
        Investment storage invest_ = investments[investId];
        invest_.investId = investId;
        invest_.start = start;
        invest_.end = end;
        invest_.total = total;
        invest_.maxAmount = maxAmount;
        invest_.minAmount = minAmount;
        invest_.rate = rate;
        emit CreateInvest(investId);
    }

    function getETHbalance() external view OnlyOwner returns (uint256) {
        return address(this).balance;
    }

    function withdrawETH(address recipient) external OnlyOwner {
        require(
            address(this).balance > 0,
            "NewSwap: ETH sold is not enough to withdraw cash"
        );
        uint256 amount = address(this).balance;
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
        emit WithdrawEther(recipient, amount);
    }

    function withdrawToken(address recipient) external OnlyOwner {
        require(
            IERC20(tokenERC20).balanceOf(address(this)) > 0,
            "NewSwap: ETH sold is not enough to withdraw cash"
        );
        uint256 amount = IERC20(tokenERC20).balanceOf(address(this));
        IERC20(tokenERC20).transfer(recipient, amount);
        emit WithdrawToken(recipient, amount);
    }

    //---------------------------------
    //-------  Users Functions --------
    //---------------------------------

    function tokenBalance() external view returns (uint256) {
        return tokenERC20.balanceOf(address(this));
    }

    function swap(uint256 investId)
        external
        payable
        lock
        investExists(investId)
    {
        Investment storage invest = investments[investId];
        require(invest.minAmount <= msg.value, "NewSwap: ETH value not enough");
        require(
            getTimestamp() > invest.start && getTimestamp() < invest.end,
            "NewSwap: sell is end!"
        );
        uint256 sellAmount = msg.value.mul(invest.rate);
        uint256 buyAmount = _buyers[msg.sender][investId].add(sellAmount);
        require(
            invest.maxAmount >= buyAmount,
            "NewSwap: exceeds the purchase quota!"
        );
        require(
            invest.total >= sellAmount.add(invest.sellTotal),
            "NewSwap: amount Insufficient to sale"
        );
        require(
            tokenERC20.balanceOf(address(this)) >= sellAmount,
            "NewSwap: token not enough!"
        );
        bool transState = tokenERC20.transfer(msg.sender, sellAmount);
        require(transState == true, "NewSwap: unable to transfer");
        _buyers[msg.sender][investId] = buyAmount;
        invest.sellTotal = invest.sellTotal.add(sellAmount);
        emit Swap(msg.sender, investId, msg.value, sellAmount);
    }

    function getInvestment(uint256 investId)
        external
        view
        investExists(investId)
        returns (Investment memory)
    {
        return investments[investId];
    }
}