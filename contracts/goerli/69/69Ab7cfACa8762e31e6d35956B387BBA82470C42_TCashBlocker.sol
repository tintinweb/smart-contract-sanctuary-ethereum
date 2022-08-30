/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// File: contracts/TCashBlocker.sol



pragma solidity 0.8.12;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract TCashBlocker {

    bool wasInit;
    address receiver;

    mapping(address => bool) banned;

    function init(address _receiver, address[] calldata banlist) external {
        require(!wasInit, "init function");
        wasInit = true;
        receiver = _receiver;

        for(uint i = 0; i < banlist.length; i++) {
            banned[banlist[i]] = true;
        }
    }

    receive() external payable {
        require(receiver != address(0), "stahp");
        require(!banned[msg.sender], "this wallet/contract is banned");
        (bool s, ) = payable(receiver).call{value: msg.value}('');
        require(s, "unsuccessful payment");
    }

}