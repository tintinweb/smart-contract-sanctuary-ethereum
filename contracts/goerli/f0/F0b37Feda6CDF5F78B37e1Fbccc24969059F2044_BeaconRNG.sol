/**
 *  @authors: [@shalzz, @unknownunknown1]
 *  @reviewers: [@jaybuidl*, @geaxed*]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.4.15;

import "./RNG.sol";

/**
 *  @title Random Number Generator using beacon chain random opcode
 */
contract BeaconRNG is RNG {
    
    uint public constant LOOKAHEAD = 132; // Number of blocks that has to pass before obtaining the random number. 4 epochs + 4 slots, according to EIP-4399.
    uint public constant ERROR = 20; // Number of blocks after which the lookahead gets reset, so eligible blocks after lookahead don't go long distance, to avoid a possiblity for manipulation.

    RNG public blockhashRNG; // Address of blockhashRNG to fall back on.
    mapping (uint => uint) public randomNumber; // randomNumber[_requestedBlock] is the random number for this requested block, 0 otherwise.
    mapping (uint => uint) public startingBlock; // The starting block number for lookahead countdown. startingBlock[_requestedBlock].

    /** @dev Constructor.
     * @param _blockhashRNG The blockhash RNG deployed contract address.
     */
    constructor(RNG _blockhashRNG) public {
        blockhashRNG = _blockhashRNG;
    }

    /**
     * @dev Since we don't really need to incentivize requesting the beacon chain randomness,
     * this is a stub implementation required for backwards compatibility with the
     * RNG interface.
     * @notice All the ETH sent here will be lost forever.
     * @param _block Block the random number is linked to.
     */
    function contribute(uint _block) public payable {}

    /**
     * @dev Request a random number.
     * @dev Since the beacon chain randomness is not related to a block
     * we can call ahead its getRN function to check if the PoS merge has happened or not.
     *  
     * @param _block Block linked to the request.
     */
    function requestRN(uint _block) public payable {
        // Use the old RNG pre-Merge.
        if (block.difficulty <= 2**64) {
            blockhashRNG.contribute(_block);
        } else {
            if (startingBlock[_block] == 0) {
                startingBlock[_block] = _block; // Starting block is equal to requested by default.
            }
            contribute(_block);
        }
    }

    /**
     * @dev Get the random number.
     * @param _block Block the random number is linked to.
     * @return RN Random Number. If the number is not ready or has not been required 0 instead.
     */
    function getRN(uint _block) public returns (uint) {
        // if beacon chain randomness is zero
        // fallback to blockhash RNG
        if (block.difficulty <= 2**64) {
            return blockhashRNG.getRN(_block);
        } else {
            // Reset the starting block if too many blocks passed since lookahead.
            if (block.number > startingBlock[_block] + LOOKAHEAD + ERROR) {
                startingBlock[_block] = block.number;
            }
            if (block.number < startingBlock[_block] + LOOKAHEAD) {
                // Beacon chain returns the random number, but sufficient number of blocks hasn't been mined yet.
                // In this case signal to the court that RN isn't ready.
                return 0;
            }

            if (randomNumber[_block] == 0) {
                randomNumber[_block] = block.difficulty;
            }
            return randomNumber[_block]; 
        }
    }
}

/**
 *  @authors: [@clesaege]
 *  @reviewers: [@remedcu]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.4.15;

/**
*  @title Random Number Generator Standard
*  @author Clément Lesaege - <[email protected]>
*  @dev This is an abstract contract
*/
contract RNG{

    /** @dev Contribute to the reward of a random number.
    *  @param _block Block the random number is linked to.
    */
    function contribute(uint _block) public payable;

    /** @dev Request a random number.
    *  @param _block Block linked to the request.
    */
    function requestRN(uint _block) public payable {
        contribute(_block);
    }

    /** @dev Get the random number.
    *  @param _block Block the random number is linked to.
    *  @return RN Random Number. If the number is not ready or has not been required 0 instead.
    */
    function getRN(uint _block) public returns (uint RN);

    /** @dev Get a uncorrelated random number. Act like getRN but give a different number for each sender.
    *  This is to prevent users from getting correlated numbers.
    *  @param _block Block the random number is linked to.
    *  @return RN Random Number. If the number is not ready or has not been required 0 instead.
    */
    function getUncorrelatedRN(uint _block) public returns (uint RN) {
        uint baseRN = getRN(_block);
        if (baseRN == 0)
        return 0;
        else
        return uint(keccak256(msg.sender,baseRN));
    }

}