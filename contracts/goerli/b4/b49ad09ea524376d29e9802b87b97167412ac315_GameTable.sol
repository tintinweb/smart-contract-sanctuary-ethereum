// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ECDSA.sol";


/**
 * @title GameTable
 * @dev For table oriented games.
 * @author sumer
 */
contract GameTable is Ownable {
    using ECDSA for bytes32;
    address private constant USDT_ADDRESS=0x55d398326f99059fF775485246999027B3197955;
    address private constant USDC_ADDRESS=0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    address private constant TOKEN = USDC_ADDRESS;
    uint playerTotal = 0;
    uint256 tableBalance = 0;
    mapping(address => uint) private usersDeposits;

    /**
     * @dev Throws if caller is not on table.
     */
    modifier onlyOnTable() {
        require(usersDeposits[msg.sender] > 0, "not on table.");
        _;
    }

    /// @dev This event is fired when a player joined table with certain amount of money.
    event PlayerJoined(address indexed player, uint256 amount);

    /// @dev This event is fired when a player checked out and settled with certain amount of money.
    event PlayerCheckedOut(address indexed player, uint256 amount);

    /// @dev This event is fired when all players checked out and certain amount of money settled to owner.
    event TableClosed(address indexed table, address indexed owner, uint256 amount);

    /// @dev This event is fired when there is a failure of validation for server hash.
    event ServerHashValidationFailure(
        address indexed table,
        address indexed player,
        uint256 amount,
        string action,
        bytes serverHash
    );

    /**
     * @dev Player join table with some deposit.
     */
    function joinTableWithDeposit(uint256 _amount, bytes memory _signature) public {
        verifyServerHash(_amount, "joinTableWithDeposit", _signature);
        IERC20(TOKEN).transferFrom(msg.sender, address(this), _amount);
        if (usersDeposits[msg.sender] == 0) {
            playerTotal ++;
        }
        usersDeposits[msg.sender] += _amount;
        tableBalance += _amount;
        emit PlayerJoined(msg.sender, _amount);
    }

    /**
     * @dev Player checkout with final settlement.
     */
    function checkOutWithSettlement(uint256 _amount, bytes memory _signature) public onlyOnTable {
        verifyServerHash(_amount, "checkOutWithSettlement", _signature);
        require(tableBalance >= _amount, "table balance is not suffcient.");
        usersDeposits[msg.sender] = 0;
        tableBalance -= _amount;
        playerTotal --;
        IERC20(TOKEN).transfer(msg.sender, _amount);
        emit PlayerCheckedOut(msg.sender, _amount);
        if (tableBalance > 0 && playerTotal == 0) {
            uint256 toTransfer = tableBalance;
            tableBalance = 0;
            IERC20(TOKEN).transfer(owner(), toTransfer);
            selfdestruct(payable(owner()));
            emit TableClosed(address(this), owner(), toTransfer);
        }
    }

    /**
     * @dev Return the accumulated balance of the contract.
     */
    function getAccumulatedBalance() public onlyOwner view returns(uint256) {
        return tableBalance;
    }

    /**
     * @dev Return the balance of the contract.
     */
    function getContractBalance() public onlyOwner view returns(uint256) {
        return IERC20(TOKEN).balanceOf(address(this));
    }

    /**
     * @dev Verify that the server hash is valid.
     */
    function verifyServerHash(uint _amount, string memory _action, bytes memory _signature) internal {
        // Validates the hash data was actually signed from 'server' side.
        bytes32 hash = keccak256(
            abi.encodePacked(
                address(this),
                msg.sender,
                _amount,
                _action
            )
        );
        bytes32 messageHash = hash.toEthSignedMessageHash();
        address signer = messageHash.recover(_signature);
        if (signer != owner()) {
            emit ServerHashValidationFailure(
                address(this),
                msg.sender,
                _amount,
                _action,
                _signature
            );
            revert("invalid signature from 'server' side.");
        }
    }
}