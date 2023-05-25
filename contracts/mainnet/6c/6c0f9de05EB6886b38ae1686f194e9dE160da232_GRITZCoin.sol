/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

//********************************************************************************
//********************************************************************************
//********************************************************************************
//*******             **.            ***     ***             **             ******
//******         *******              *       *                              *****
//******       **     **       ****   *       *              **              *****
//******         **    *              *       ******    ,***********,    *********
//******               *       **   ***       ******    *******              *****
//********************************************************************************
//********************************************************************************
//********************************************************************************
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract GRITZCoin {
    string public name = "GRITZ";
    string public symbol = "GRITZ";
    uint256 public totalSupply = 10**12 * 10**18; // 1 Trillion
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public isBlacklisted;

    uint256 public TEAM_SUPPLY;
    uint256 public STAKING_SUPPLY;
    uint256 public PUBLIC_SUPPLY;

    address public owner;
    address public teamWallet = 0xf08038659cBA11643b76a16F1C909d68039C2f7f;
    address public stakingWallet = 0x3a1E4b2Ce35d9c27dFB91FBaFEB8a771254b80Aa;
    address public publicWallet;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event WalletBlacklisted(address indexed wallet);
    event OwnershipRevoked(address indexed previousOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
        PUBLIC_SUPPLY = totalSupply * 50 / 100; // 50% to public wallet
        STAKING_SUPPLY = totalSupply * 40 / 100; // 40% to staking wallet
        TEAM_SUPPLY = totalSupply * 10 / 100; // 10% to team wallet

        publicWallet = msg.sender;
        balanceOf[teamWallet] = TEAM_SUPPLY;
        balanceOf[stakingWallet] = STAKING_SUPPLY;
        balanceOf[publicWallet] = PUBLIC_SUPPLY;
        emit Transfer(address(0), teamWallet, TEAM_SUPPLY);
        emit Transfer(address(0), stakingWallet, STAKING_SUPPLY);
        emit Transfer(address(0), publicWallet, PUBLIC_SUPPLY);
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
    require(!isBlacklisted[msg.sender], "Sender is blacklisted");
    require(_value > 0 && balanceOf[msg.sender] >= _value, "Insufficient balance");

    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;

    emit Transfer(msg.sender, _to, _value);

    return true;
}

    function approve(address _spender, uint256 _value) external returns (bool success) {
        require(_spender != address(0), "Cannot approve to zero address");
        require(!isBlacklisted[msg.sender], "Sender is blacklisted");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(_to != address(0), "Cannot transfer to zero address");
        require(!isBlacklisted[_from], "Sender is blacklisted");
        require(_value > 0 && balanceOf[_from] >= _value && allowance[_from][msg.sender] >= _value, "Insufficient balance or allowance");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function burn(uint256 _value) external returns (bool success) {
        require(_value > 0 && balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(!isBlacklisted[msg.sender], "Sender is blacklisted");

        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;

        emit Transfer(msg.sender, address(0), _value);

        return true;
    }

    function getTotalSupplyInGRITZ() public view returns (uint256) {
        return totalSupply / (10 ** decimals);
    }

    function getTeamSupply() external view returns (uint256) {
        return balanceOf[teamWallet];
    }

    function getStakingSupply() external view returns (uint256) {
        return balanceOf[stakingWallet];
    }

    function getPublicSupply() external view returns (uint256) {
        return balanceOf[publicWallet];
    }

    function blacklistWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0), "Cannot blacklist zero address");
        require(!isBlacklisted[_wallet], "Wallet is already blacklisted");

        isBlacklisted[_wallet] = true;
        emit WalletBlacklisted(_wallet);
    }

    function revokeOwnership() external onlyOwner {
        emit OwnershipRevoked(owner);
        owner = address(0);
    }
}