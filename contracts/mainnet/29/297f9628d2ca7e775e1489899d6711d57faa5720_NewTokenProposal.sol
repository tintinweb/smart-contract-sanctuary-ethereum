/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function symbol() external view returns(string memory);
    function name() external view returns(string memory);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IXUSD {
    function addStable(address stable) external;
    function getOwner() external view returns (address);
}

contract NewTokenProposal {

    // most recent token proposed
    address public pendingStableToken;

    // time token was proposed
    uint256 public proposedTimestamp;

    // wait time for proposition approval
    uint256 public constant propositionWaitTime = 800000; // 28 day approval period

    // XUSD Token
    address public XUSD;

    // owner
    modifier onlyOwner(){
        require(msg.sender == getOwner(), 'Only Owner');
        _;
    }

    // Events
    event StableProposed(address stable);
    event StableApproved(address stable);

    constructor(){
        proposedTimestamp = block.number;
    }

    function approvePendingStable() external onlyOwner {
        require(pendingStableToken != address(0), 'Invalid Stable');
        require(proposedTimestamp + propositionWaitTime <= block.number, 'Insufficient Time Has Passed');

        // add stable to XUSD
        IXUSD(XUSD).addStable(pendingStableToken);
        emit StableApproved(pendingStableToken);

        // clear up data
        pendingStableToken = address(0);
        proposedTimestamp = block.number;
    }

    function proposeStable(address stable) external onlyOwner {
        require(stable != address(0), 'Zero Address');
        require(IERC20(stable).decimals() == 18, 'Stable Must Have 18 Decimals');

        pendingStableToken = stable;
        proposedTimestamp = block.number;

        emit StableProposed(stable);
    }

    function pairXUSD(address XUSD_) external {
        require(
            XUSD == address(0) &&
            XUSD_ != address(0),
            'token paired'
        );
        XUSD = XUSD_;
    }

    function getOwner() public view returns (address) {
        return IXUSD(XUSD).getOwner();
    }
}