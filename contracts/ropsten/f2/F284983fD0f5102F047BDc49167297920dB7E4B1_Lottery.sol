/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


contract Lottery is Initializable {
    address payable manager;
    address payable[] players;
    address payable winner;
    uint round;

    function initialize() public initializer {
        manager = payable(msg.sender);
    }

    // ??????onlyManager?????????
    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }

    /*
     * ??????
     */
    function play() payable public {
        require(msg.value == 1 ether);
        players.push(payable(msg.sender));
    }

    /*
     * ??????
     */
    function runLottery() public onlyManager {
        // ??????2????????????????????????
        require(players.length > 1);

        // ???????????????
        uint v = uint(sha256(abi.encodePacked(block.timestamp, players.length)));
        // ???????????????players.length?????????????????????????????????
        uint index = v % players.length;

        winner = players[index];

        dividePrizePool();

        round++;
        delete players;
    }

    /*
     * ????????????
     */
    function dividePrizePool() private {
        uint winnerDivide = address(this).balance * 99 / 100;
        uint managerDivide = address(this).balance - winnerDivide;

        winner.transfer(winnerDivide);
        manager.transfer(managerDivide);
    }

    /*
     * ??????
     */
    function refund() public onlyManager {
        for (uint i = 0; i < players.length; i++) {
            players[i].transfer(1 ether);
        }

        round++;
        delete players;
    }

    /*
     * ?????????????????????
     */
    function getManager() public view returns (address) {
        return manager;
    }

    /*
     * ??????????????????
     */
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    /*
     * ???????????????
     */
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    /*
     * ?????????????????????
     */
    function getPlayersCount() public view returns (uint) {
        return players.length;
    }

    /*
     * ???????????????
     */
    function getWinner() public view returns (address) {
        return winner;
    }

    /*
     * ??????????????????
     */
    function getRound() public view returns (uint) {
        return round;
    }
}