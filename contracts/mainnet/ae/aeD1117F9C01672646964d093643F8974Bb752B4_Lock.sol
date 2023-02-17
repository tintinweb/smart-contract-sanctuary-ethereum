/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: MIT
// Author: tycoon.eth
// Project: Cigarettes (CEO of CryptoPunks)
// Perma-lock liquidity
pragma solidity ^0.8.17;


/*
This contract's lock() function is used to deposit CIG/ETH SLP tokens to the
CIG factory. Once locked, they are locked forever.


Anybody can call this contract to harvest, and the harvested CIG will be
stored in this contract.

The admin can also assign "stipends" for individual addresses. When the
harvest is called by an address with a stipend, the harvest function will send
CIG tokens as specified by the stipend.

*/

contract Lock {

    // Structs
    struct Stipend {
        address to;    // where to send harvested CIG rewards to
        uint256 amount;// max CIG that will be sent
        uint256 period;// how many blocks required between calls
        uint256 block; // record of last block number when called
    }

    // Events
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event StipendGranted(
        address indexed caller,
        address to,
        uint256 limit,
        uint256 period
    );
    event StipendRevoked(address indexed spender);

    // State
    mapping(address => Stipend) public stipends;       // caller => Stipend
    address public admin;                              // can permit other callers to harvest CIG
    ICigToken private immutable cig;                   // 0xCB56b52316041A62B6b5D0583DcE4A8AE7a3C629
    ILiquidityPool private immutable cigEthSLP;        // 0x22b15c7ee1186a7c7cffb2d942e20fc228f6e4ed (SLP, it's also an ERC20)

    constructor (address _cig, address _slp) {
        admin = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
        cig = ICigToken(_cig);
        cigEthSLP = ILiquidityPool(_slp);
        cigEthSLP.approve(_cig, type(uint256).max);    // allow Cigtoken to spend our SLP
    }

    modifier onlyOwner() {
        require(admin == msg.sender, "must be admin");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(admin, address(0));
        admin = address(0);
    }

    function transferOwnership(address _to) public onlyOwner {
        require(_to != address(0), "_to must not be 0x0");
        emit OwnershipTransferred(admin, _to);
        admin = _to;
    }

    /**
    * grant grants a stipend for a caller. When harvest() is called with
    * msg.sender as the caller, the contract will send _amount to _to
    * Must wait _period of blocks between calls.
    */
    function grant(
        address _caller,
        address _to,
        uint256 _amount,
        uint256 _period
    ) external onlyOwner {
        require (_to != address(0), "_to cannot be 0x0x");
        Stipend storage s = stipends[_caller];
        require(s.to == address(0), "slot must be empty");
        s.to = _to;
        s.amount = _amount;
        s.period = _period;
        emit StipendGranted(_caller, _to, _amount, _period);
    }

    /**
    * revoke revokes a given stipend for the _caller
    */
    function revoke(address _caller) external onlyOwner {
        require (stipends[_caller].to != address(0), "invalid stipend");
        delete stipends[_caller];
        emit StipendRevoked(_caller);
    }

    /**
    * @dev lock liquidity forever. There is no way to withdraw
    */
    function lock(uint256 _amount) external {
        cigEthSLP.transferFrom(
            msg.sender,
            address(this),
            _amount
        );                    // get their SLP token
        cig.deposit(_amount); // deposit into the CIG Factory.
    }

    /**
    * @dev harvest CIG. If msg.sender has stipend then send their CIG
    */

    function harvest() external {
        cig.harvest();                                     // harvested CIG will be sent to this contract
        Stipend memory s = stipends[msg.sender];
        if (s.to != address(0)) {
            if (block.number - s.period > s.block) {
                uint256 a = s.amount;
                uint256 b = cig.balanceOf(address(this));
                if (a > b) {
                    a = b;
                }
                stipends[msg.sender].block = block.number; // record the block number
                cig.transfer(s.to, a);                     // send CIG stipend
            }
        }
    }

    function getStats(address _user) view external returns(uint256[] memory) {
        uint[] memory ret = new uint[](12);
        ret[0] = cig.pendingCig(address(this));
        (ret[1], ret[2],)  = cigEthSLP.getReserves();
        ICigToken.UserInfo memory i = cig.farmers(address(this));
        ret[3] = i.deposit;
        ret[4] = i.rewardDebt;
        ret[5] = cigEthSLP.totalSupply();
        ret[6] = cig.balanceOf(address(this));
        Stipend memory s = stipends[_user];
        ret[7] = uint256(uint160(s.to));
        ret[8] = s.block;
        ret[9] = s.period;
        ret[10] = s.amount;
        ret[11] = cig.stakedlpSupply();
        return ret;
    }
}

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

interface ICigToken is IERC20 {
    struct UserInfo {
        uint256 deposit;    // How many LP tokens the user has deposited.
        uint256 rewardDebt; // keeps track of how much reward was paid out
    }
    //function emergencyWithdraw() external; // make sure to call harvest before calling this
    function harvest() external;
    function deposit(uint256 _amount) external;
    function pendingCig(address) external view returns (uint256);
    function cigPerBlock() external view returns (uint256);
    function farmers(address _user) external view returns (UserInfo memory);
    function stakedlpSupply() external view returns(uint256);

    //function withdraw(uint256 _amount) external // bugged, use emergencyWithdraw() instead.
}

interface ILiquidityPool is IERC20 {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function token0() external view returns (address);
}