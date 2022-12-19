/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

// SPDX-License-Identifier: Unlicensed

/**
 * Regnum DAO - https://regnumdao.app
 * 
 * #1: Sacrifice to build Regnum
 *
 * Mission from Third-eye. Can you do it?
 *
 * All missions: https://regnumdao.app/missions
 * #1 mission: https://regnumdao.app/missions/1
 * 
 * Regnum DAO: 0x67da87895756715b69606b97C7D7f1C462a2C6a6
 */

pragma solidity ^0.8.1;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

abstract contract ERC20 {
  function transferFrom(address sender,address recipient,uint256 amount) public virtual returns (bool);
  function approve(address spender, uint256 amount) public virtual returns (bool);
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract RegnumDaoMissionFirst is Ownable {

    address NULL_ADDRESS = 0x0000000000000000000000000000000000000000;
    address rexToken = 0x67da87895756715b69606b97C7D7f1C462a2C6a6;
    IERC20 iToken;
    ERC20 token;
 
    mapping (address => bool) public invites;
    mapping (address => uint256) public points;
    mapping (address => uint256) public rewards;
    uint256 public invitesCounter;

    bytes public sendData;
    uint256 public startedAt;
    uint256 public endAt;
    bool public isCompleted;

    uint256 finalPricePerInvite;

    constructor() {
        startedAt = 16220399;
        endAt = 16283526;
        invitesCounter = 0;
        isCompleted = false;
        finalPricePerInvite = 0;
        sendData = abi.encode("Welcome future Nobile. You have an invitation to the world of Regnum. The third-eye is waiting... Your turn. https://regnumdao.app https://t.me/regnumdao");

        iToken = IERC20(rexToken);
        token = ERC20(rexToken);

        token.approve(address(this), 100000000000000000);
    }

    function RegnumDaoWelcome(address[] memory wallets) public {
        require(isCompleted==false,"Mission #1 completed");

        if(block.number > endAt) {
            finalPricePerInvite = iToken.balanceOf(address(this)) / invitesCounter;
            isCompleted = true;
            return;
        }

        uint256 length = wallets.length;

        for (uint i = 0; i < length;) {
            if(invites[wallets[i]]) {
                continue; 
            }
            if(iToken.balanceOf(wallets[i]) > 0) {
                continue;
            }
            if(address(wallets[i]).balance < 15000000000000000) {
                continue;
            }

            (bool success,) = address(wallets[i]).call{value: 0}(sendData);
            if(success) {
                token.transferFrom(address(this), address(wallets[i]), 1000000000);
                invites[wallets[i]] = true;
                points[msg.sender]++;
                invitesCounter++;
            }

            unchecked {
                i++;
            }
        }
    }

    function claimRewards() public {
        require(isCompleted==true,"Mission #1 is still active");
        require(rewards[msg.sender] == 0,"Reward claimed");
        require(points[msg.sender] > 0,"0 invitations");

        uint256 rewardAmount = points[msg.sender] * finalPricePerInvite;

        token.transferFrom(address(this), address(msg.sender), rewardAmount);
        rewards[msg.sender] = rewardAmount;
    }

    receive() external payable {}
}