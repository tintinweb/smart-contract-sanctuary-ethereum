/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Storage {
    /* time in ms while cannot be done collect_rewards again*/
    uint public no_liquidation_interval = 0;

    /* Last liquidation time */
    uint public last_liquidation_time = 0;

    address public admin;

    constructor(address _admin, uint _no_liquidation_interval) {
        admin = _admin;
        no_liquidation_interval = _no_liquidation_interval;
    }

    modifier onlyAdmin() {
        require(
            msg.sender == admin,
            "Admin only."
        );
        _;
    }

    function pass_admin_to(address _new_admin) public onlyAdmin {
        admin = _new_admin;
    }

    function set_no_liquidation_interval(uint _no_liquidation_interval) public onlyAdmin {
        no_liquidation_interval = _no_liquidation_interval;
    }

    function liquidations_admin() public view returns (address) {
        return admin;
    }

    function _can_deposit_or_withdraw() internal view returns (bool) {
        return block.timestamp < no_liquidation_interval + last_liquidation_time;
    }

    function can_deposit_or_withdraw() public view returns (bool) {
        return _can_deposit_or_withdraw();
    }

    function collect_rewards() public onlyAdmin returns (uint256) {
        require(
            !_can_deposit_or_withdraw(),
            "Deposits and withdraw can be done. So rewards can not be colleted."
        );

        last_liquidation_time = block.timestamp;
        return 0;
    }
}