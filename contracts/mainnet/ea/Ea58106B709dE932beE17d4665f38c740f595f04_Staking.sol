// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface FounderCards {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function balanceOf(address account) external view returns (uint256);

    function getIDsByOwner(address owner) external view returns (uint256[] memory);
}

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);
}

struct Deposit {
    uint256 tokens;
    uint256 stakers;
    uint256 timestamp;
}

contract Staking {
    IERC20 token;
    FounderCards founder_cards;
    mapping(uint256 => uint256) next_withdrawable_deposit_by_foundercard;
    mapping(bytes32 => address) staker_by_foundercard_and_deposit;
    uint256 public stakers = 0;
    mapping(uint256 => Deposit) public deposits_by_index;
    uint256 public deposit_count;
    address public contract_owner;

    address constant UNSTAKE_ADDRESS = 0x0123456789012345678901234567890123456789;

    constructor(address address_token, address address_founder_cards) {
        founder_cards = FounderCards(address_founder_cards);
        token = IERC20(address_token);
        contract_owner = msg.sender;
    }

    function transfer_ownership(address new_owner) public {
        require(msg.sender == contract_owner, "You are not the owner");
        contract_owner = new_owner;
    }

    function deposit(uint256 amount) public {
        require(msg.sender == contract_owner, "You are not the owner");
        token.transferFrom(msg.sender, address(this), amount);
        deposits_by_index[deposit_count] = Deposit(amount, stakers, block.timestamp);
        deposit_count++;
    }

    function stake(uint256 foundercard) public {
        require(msg.sender == founder_cards.ownerOf(foundercard), "You are not the owner of this Founder's card!");
        if(!was_staked(foundercard, deposit_count)) {
            stakers++;
        }
        set_staker(foundercard, msg.sender);
    }

    function stake_all() public {
        uint256[] memory ids = founder_cards.getIDsByOwner(msg.sender);
        for(uint256 i = 0; i < ids.length; i++) {
            stake(ids[i]);
        }
    }

    function unstake(uint256 foundercard) public {
        address staker = get_staker(foundercard, deposit_count);
        address owner = founder_cards.ownerOf(foundercard);
        require(staker != address(0), "This Founder's card is not staked.");
        require(staker != owner, "The staker of this founder's card still owns it.");
        set_staker(foundercard, UNSTAKE_ADDRESS);
        stakers--;
    }

    function withdraw(uint256 foundercard) public {
        require(msg.sender == founder_cards.ownerOf(foundercard), "You are not the owner of this Founder's card!");
        uint256 balance = get_balance(foundercard);
        next_withdrawable_deposit_by_foundercard[foundercard] = deposit_count;
        token.transfer(msg.sender, balance);
    }

    function withdraw_all() public {
        uint256[] memory owned_founder_cards = founder_cards.getIDsByOwner(msg.sender);
        uint256 total_balance = 0;
        for(uint256 i = 0; i < owned_founder_cards.length; i++) {
            uint256 foundercard = owned_founder_cards[i];
            total_balance += get_balance(foundercard);
            next_withdrawable_deposit_by_foundercard[foundercard] = deposit_count;
        }
        token.transfer(msg.sender, total_balance);
    }

    function get_staker_entry(uint256 foundercard, uint256 deposit_index) private view returns(address) {
        bytes32 index = sha256(abi.encodePacked(foundercard, deposit_index));
        return staker_by_foundercard_and_deposit[index];
    }

    function set_staker(uint256 foundercard, address staker) private {
        bytes32 index = sha256(abi.encodePacked(foundercard, deposit_count));
        staker_by_foundercard_and_deposit[index] = staker;
    }

    function was_staked(uint256 foundercard, uint256 deposit_index) public view returns(bool) {
        address staker = get_staker(foundercard, deposit_index);
        return staker != address(0);
    }

    function get_staker(uint256 foundercard, uint256 deposit_index) public view returns(address) {
        for(int256 i = int(deposit_index); i >= 0; i--) {
            address staker = get_staker_entry(foundercard, deposit_index);
            if(staker == address(0)) {
                continue;
            }
            if(staker == UNSTAKE_ADDRESS) {
                return address(0);
            }
            return staker;
        }
        return address(0);
    }

    function get_balance(uint256 foundercard) public view returns(uint256) {
        uint256 balance = 0;
        for(uint256 i = next_withdrawable_deposit_by_foundercard[foundercard]; i < deposit_count; i++) {
            Deposit memory deposit_i = deposits_by_index[i];
            if(was_staked(foundercard, i)) {
                balance += deposit_i.tokens / deposit_i.stakers;
            }
        }
        return balance;
    }
}