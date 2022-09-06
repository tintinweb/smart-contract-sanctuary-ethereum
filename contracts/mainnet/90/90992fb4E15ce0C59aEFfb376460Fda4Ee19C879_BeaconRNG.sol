/**
 *  @authors: [@shalzz*, @unknownunknown1]
 *  @reviewers: [@jaybuidl, @geaxed*, clesaege]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.4.15;

import "./RNG.sol";

/**
 *  @title Random Number Generator using beacon chain random opcode
 */
contract BeaconRNG {
    
    uint public constant LOOKAHEAD = 132; // Number of blocks that has to pass before obtaining the random number. 4 epochs + 4 slots, according to EIP-4399.
    uint public constant ERROR = 32; // Number of blocks after which the lookahead gets reset, so eligible blocks after lookahead don't go long distance, to avoid a possiblity for manipulation.

    RNG public blockhashRNGFallback; // Address of blockhashRNGFallback to fall back on.

    /** @dev Constructor.
     * @param _blockhashRNGFallback The blockhash RNG deployed contract address.
     */
    constructor(RNG _blockhashRNGFallback) public {
        blockhashRNGFallback = _blockhashRNGFallback;
    }

    /**
     * @dev Request a random number. It is not used by this contract and only exists for backward compatibility.
     */
    function requestRN(uint /*_block*/) public pure {}

    /**
     * @dev Get an uncorrelated random number.
     * @param _block Block the random number is linked to.
     * @return RN Random Number. If the number is not ready or has not been required 0 instead.
     */
    function getUncorrelatedRN(uint _block) public returns (uint) {
        // Pre-Merge.
        if (block.difficulty <= 2**64) {
            uint baseRN = blockhashRNGFallback.getRN(_block);
            if (baseRN == 0) {
                return 0;
            } else {
                return uint(keccak256(abi.encodePacked(msg.sender, baseRN)));
            }
        // Post-Merge.
        } else {
            if (block.number > _block && (block.number - _block) % (LOOKAHEAD + ERROR) >= LOOKAHEAD) {
                // Eligible block number should exceed LOOKAHEAD but shouldn't be higher than LOOKAHEAD + ERROR.
                // In case of the latter LOOKAHEAD gets reset.  
                return uint(keccak256(abi.encodePacked(msg.sender, block.difficulty)));
            } else {
                return 0;
            }
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