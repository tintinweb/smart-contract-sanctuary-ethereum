// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

/**
 * @dev Dummy raffle contract to test calls from the minter contract
 */

contract RaffleDummy {

    address public minter;

    uint256 public raffleInput_counter;

    struct RaffleInputData{
        uint256 _raffleId;
        uint256 _amountOfEntries;
        address _player;
    }

    mapping(uint256 => RaffleInputData) public raffleInput;

    constructor(){
        setMinter(msg.sender);
    }

    function setMinter(address minterAddr) public {
        minter = minterAddr;
    }

    /**
     * @dev Gets entries for a promo raffle. Only callable by the minter contract.
     * Minter contract must have the "MINTERCONTRACT" role assigned in the raffle contract.
     * @param _raffleId Id of the raffle.
     * @param _amountOfEntries Amount of entries.
     * @param _player Address of the user.
     */
    function createFreeEntriesFromExternalContract(
        uint256 _raffleId,
        uint256 _amountOfEntries,
        address _player
    ) external {
        require(msg.sender == minter, "Caller is not minter contract");

        raffleInput[raffleInput_counter] = RaffleInputData(_raffleId, _amountOfEntries, _player);

        ++raffleInput_counter;
    }

}