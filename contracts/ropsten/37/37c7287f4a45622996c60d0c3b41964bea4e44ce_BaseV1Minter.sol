/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

library Math {
    function max(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }
}

interface ve {
    function token() external view returns (address);
    function totalSupply() external view returns (uint);
    function create_lock_for(uint, uint, address) external returns (uint);
    function transferFrom(address, address, uint) external;
}

interface underlying {
    function approve(address spender, uint value) external returns (bool);
    function mint(address, uint) external;
    function totalSupply() external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function transfer(address, uint) external returns (bool);
}

interface voter {
    function notifyRewardAmount(uint amount) external;
}

interface ve_dist {
    function checkpoint_token() external;
    function checkpoint_total_supply() external;
}

// codifies the minting rules as per ve(3,3), abstracted from the token to support any token that allows minting

contract BaseV1Minter {

    uint internal constant week = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
    uint internal constant emission = 98;
    uint internal constant tail_emission = 8;
    uint internal constant target_base = 100; // 2% per week target emission
    uint internal constant tail_base = 1000; // 0.2% per week target emission
    uint public constant dev_share = 20;
    underlying public immutable _token;
    voter public immutable _voter;
    ve public immutable _ve;
    ve_dist public immutable _ve_dist;
    address public dev_addr;
    uint public weekly = 5000000e18;
    bool public tail_emission_on = false;
    uint public active_period;
    uint internal constant lock = 86400 * 7 * 12;

    address internal initializer;

    event Mint(address indexed sender, uint weekly, uint circulating_supply, uint circulating_emission);

    constructor(
        address __voter, // the voting & distribution system
        address  __ve, // the ve(3,3) system that will be locked into
        address __ve_dist // the distribution system that ensures users aren't diluted
    ) {
        initializer = msg.sender;
        _token = underlying(ve(__ve).token());
        _voter = voter(__voter);
        _ve = ve(__ve);
        _ve_dist = ve_dist(__ve_dist);
        active_period = block.timestamp / week * week;
    }

    function initialize(
        address[] memory claimants,
        uint[] memory amounts,
        uint max, // sum amounts / max = % ownership of top protocols, so if initial 20m is distributed, and target is 25% protocol ownership, then max - 4 x 20m = 80m
        address _dev_addr // the team distribution address
    ) external {
        require(initializer == msg.sender);
        _token.mint(address(this), max);
        _token.approve(address(_ve), type(uint).max);
        for (uint i = 0; i < claimants.length; i++) {
            _ve.create_lock_for(amounts[i], lock, claimants[i]);
        }
        initializer = address(0);
        dev_addr = _dev_addr;
        active_period = (block.timestamp + week) / week * week;
    }

    // calculate circulating supply as total token supply - locked supply
    function circulating_supply() public view returns (uint) {
        return _token.totalSupply() - _ve.totalSupply();
    }

    // emission calculation is 2% of available supply to mint adjusted by circulating / total supply
    function calculate_emission() public view returns (uint) {
        return weekly * emission * circulating_supply() / target_base / _token.totalSupply();
    }

    // weekly emission takes the max of calculated (aka target) emission versus circulating tail end emission
    function weekly_emission() public view returns (uint, bool) {
        uint target = calculate_emission();
        uint tail = circulating_emission();
        return target >= tail? (target, false) : (tail, true);
    }

    // weekly emission takes the max of calculated (aka target) emission versus circulating tail end emission
    function calculate_dev_reward(uint _weekly) internal pure returns (uint) {
        return _weekly * dev_share / 100;
    }

    // calculates tail end (infinity) emissions as 0.2% of total supply
    function circulating_emission() public view returns (uint) {
        return circulating_supply() * tail_emission / tail_base;
    }

    // calculate inflation and adjust ve balances accordingly
    function calculate_growth(uint _minted) public view returns (uint) {
        return _ve.totalSupply() * _minted / _token.totalSupply();
    }

    // update period can only be called once per cycle (1 week)
    function update_period() external returns (uint) {
        uint _period = active_period;
        if (block.timestamp >= _period + week && initializer == address(0)) { // only trigger if new week
            _period = block.timestamp / week * week;
            active_period = _period;
            (weekly, tail_emission_on) = weekly_emission();

            if(tail_emission_on) {
                uint _growth = calculate_growth(weekly);
                uint _required = _growth + weekly;
                uint _balanceOf = _token.balanceOf(address(this));
                if (_balanceOf < _required) { // Cannot be if tail_emission_on is false
                    _token.mint(address(this), _required-_balanceOf);
                }
                require(_token.transfer(address(_ve_dist), _growth));
                _ve_dist.checkpoint_token(); // checkpoint token balance that was just minted in ve_dist
                _ve_dist.checkpoint_total_supply(); // checkpoint supply
            }

            uint devReward = calculate_dev_reward(weekly);
            require(_token.transfer(address(dev_addr), devReward));
            weekly -= devReward;

            _token.approve(address(_voter), weekly);
            _voter.notifyRewardAmount(weekly);

            emit Mint(msg.sender, weekly, circulating_supply(), circulating_emission());
        }
        return _period;
    }

    function dev(address _dev_addr) public {
        require(msg.sender == dev_addr);
        dev_addr = _dev_addr;
    }

}