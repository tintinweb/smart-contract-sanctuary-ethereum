/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

//SPDX-License-Identifier:Unlicensed
pragma solidity ^0.8.7;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract Subscription {
    IERC20 private immutable erc20;
    IERC721 private immutable erc721;

    uint32 public immutable extensionPeriod;
    uint256 public subscriptionFee;
    uint256 public subscriptionFee3;
    uint32 public immutable subscriptionPeriod;
    uint32 public immutable subscriptionPeriod3;

    address public owner;
    mapping(address => uint32) public subscriptionStatus;
    mapping(address => uint32) public referrers;

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "UniswapV2: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(
        address _tokenAddress,
        address _nftAddress,
        uint32 _extensionPeriod,
        uint32 _subscriptionPeriod,
        uint32 _subscriptionPeriod3,
        uint256 _subscriptionFee,
        uint256 _subscriptionFee3
    ) {
        owner = msg.sender;
        erc20 = IERC20(_tokenAddress);
        erc721 = IERC721(_nftAddress);
        extensionPeriod = _extensionPeriod;
        subscriptionPeriod = _subscriptionPeriod;
        subscriptionPeriod3 = _subscriptionPeriod3;
        subscriptionFee = _subscriptionFee;
        subscriptionFee3 = _subscriptionFee3;
    }

    function subscribe(address subscriber, bytes20 referralCode) public lock {
        uint32 tokenId = uint32(uint160(referralCode) % 10000);

        if (subscriptionStatus[subscriber] < block.timestamp) {
            subscriptionStatus[subscriber] =
                uint32(block.timestamp) +
                subscriptionPeriod;
        } else {
            require(
                subscriptionStatus[subscriber] - extensionPeriod <
                    block.timestamp,
                "Too early to extend subscription"
            );
            subscriptionStatus[subscriber] += subscriptionPeriod;
        }

        if (referrers[subscriber] == 0) {
            referrers[subscriber] = tokenId;
        }

        if (referralCode > 0) {
            uint256 commission = subscriptionFee / 2;
            address referralAddress = erc721.ownerOf(referrers[subscriber]);
            erc20.transferFrom(subscriber, referralAddress, commission);
            erc20.transferFrom(subscriber, owner, subscriptionFee - commission);
        } else {
            erc20.transferFrom(subscriber, owner, subscriptionFee);
        }
    }

    function subscribe3(bytes20 referralCode) public lock {
        address subscriber = msg.sender;
        uint32 tokenId = uint32(uint160(referralCode) % 10000);

        if (subscriptionStatus[subscriber] < block.timestamp) {
            subscriptionStatus[subscriber] = uint32(block.timestamp) + subscriptionPeriod3;
        } else {
            subscriptionStatus[subscriber] += subscriptionPeriod3;
        }

        if (referrers[subscriber] == 0) {
            referrers[subscriber] = tokenId;
        }

        if (referralCode > 0) {
            uint256 commission = subscriptionFee3 / 2;
            address referralAddress = erc721.ownerOf(referrers[subscriber]);
            erc20.transferFrom(subscriber, referralAddress, commission);
            erc20.transferFrom(subscriber, owner, subscriptionFee3 - commission);
        } else {
            erc20.transferFrom(subscriber, owner, subscriptionFee3);
        }
    }

    function set_subscription_fee(uint256 _subscriptionFee) public {
        require(msg.sender == owner, "No permission");
        subscriptionFee = _subscriptionFee;
    }

    function set_subscription_fee3(uint256 _subscriptionFee3) public {
        require(msg.sender == owner, "No permission");
        subscriptionFee3 = _subscriptionFee3;
    }

    function transfer_ownership(address new_owner) public {
        require(msg.sender == owner, "No permission");
        owner = new_owner;
    }
}