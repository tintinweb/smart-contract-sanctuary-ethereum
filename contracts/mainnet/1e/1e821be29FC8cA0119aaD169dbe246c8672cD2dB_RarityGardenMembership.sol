/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IERC20
{

    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
}

interface IERC721
{

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract RarityGardenMembership
{

    struct Membership
    {
        uint256 tier;
        uint256 expirationDate;
        bytes data;
    }

    struct Tier
    {
        bool active;
        uint256 price;
        uint256 duration;
        address accessToken;
    }

    address public owner;
    Tier[] public tiers;
    mapping(address => mapping(uint256 => Membership)) public memberships;

    event EthRecovered(uint256 amount);
    event Erc20Recovered(address token, uint256 amount);
    event Erc721Recovered(address collection, uint256 token_id);
    event Joined(address member, uint256 tier, uint256 price, uint256 expirationDate, bytes data);

    constructor()
    {

        owner = msg.sender;
        
        tiers.push(Tier({
            active : false,
            price : 0,
            duration : 0,
            accessToken : address(0)
        }));
    }

    function join(uint256 tier, bytes calldata data) external payable
    {

        uint256 timestamp = block.timestamp;
        address msgSender = msg.sender;
        Membership memory membership = memberships[msgSender][tier];
        require(membership.expirationDate <= timestamp, "Membership is still active.");
        Tier memory _tier = tiers[tier];
        require(_tier.active, "Tier is disabled for new joins.");
        address nullAddress = address(0);
        address thisAddress = address(this);
        uint256 expirationDate = timestamp + _tier.duration;

        memberships[msgSender][tier] = Membership({
            tier: tier,
            expirationDate: expirationDate,
            data : data
        });

        emit Joined(msgSender, tier, _tier.price, expirationDate, data);

        if(_tier.accessToken != nullAddress)
        {
            
            uint256 balance = IERC20(_tier.accessToken).balanceOf(thisAddress);
            bool success = IERC20(_tier.accessToken).transferFrom(msgSender, thisAddress, _tier.price);
            require(success, "Token access failed.");
            require(balance + _tier.price == IERC20(_tier.accessToken).balanceOf(thisAddress), "Please send the exact token amount."); 
        }
        else
        {
            
            require(msg.value == _tier.price, "Please send the exact ETH amount.");
        }
    }

    function getTierLength() external view returns(uint256){

        return tiers.length;
    }

    function addTier(Tier calldata tier) external
    {

        require(owner == msg.sender, "Not the owner");

        tiers.push(tier);
    }

    function updateTier(Tier calldata tier, uint256 tierIndex) external
    {

        require(owner == msg.sender, "Not the owner");

        tiers[tierIndex] = tier;
    }

    function deactivateTier(uint256 tier) external
    {

        require(owner == msg.sender, "Not the owner");

        tiers[tier].active = false;
    }

    function activateTier(uint256 tier) external
    {

        require(owner == msg.sender, "Not the owner");

        tiers[tier].active = true;
    }

    function resetMembership(address member, uint256 tierIndex) external
    {

        require(owner == msg.sender, "Not the owner");

        memberships[member][tierIndex] = Membership({
            tier: 0,
            expirationDate: 0,
            data : hex''
        });
    }

    function performEthRecover(uint256 amount) external
    {
        address msgSender = msg.sender;

        require(msgSender == owner, "Not the owner");

        (bool success,) = payable(msgSender).call{value: amount}("");

        if(success)
        {
            emit EthRecovered(amount);
        }
    }

    function performErc20Recover(address tokenAddress, uint256 amount) external
    {
        address msgSender = msg.sender;

        require(msgSender == owner, "Not the owner");

        bool success = IERC20(tokenAddress).transfer(msgSender, amount);

        if(success)
        {
            emit Erc20Recovered(tokenAddress, amount);
        }
    }

    function performErc721Recover(address collection, uint256 token_id) external
    {
        address msgSender = msg.sender;

        require(msgSender == owner, "Not the owner");

        IERC721(collection).safeTransferFrom(address(this), msgSender, token_id);

        emit Erc721Recovered(collection, token_id);
    }

    function transferOwnership(address newOwner) external
    {
        require(msg.sender == owner, "Not the owner");

        owner = newOwner;
    }
}