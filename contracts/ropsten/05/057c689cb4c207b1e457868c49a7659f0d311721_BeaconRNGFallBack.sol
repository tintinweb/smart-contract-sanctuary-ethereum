/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// File: github/2kleros/kleros-interaction/contracts/standard/rng/RNG.sol

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

// File: github/2kleros/kleros-interaction/contracts/standard/rng/BeaconRNGFallback.sol

 /**
 *  @authors: [@shalzz]
 *  @reviewers: [@jaybuidl*, @geaxed]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.4.15;


/**
 *  @title Random Number Generator using beacon chain random opcode
 */
contract BeaconRNGFallBack is RNG {

    RNG public beaconRNG;
    RNG public blockhashRNG;

    /** @dev Constructor.
     * @param _beaconRNG The beacon chain RNG deployed contract address
     * @param _blockhashRNG The blockhash RNG deployed contract address
     */
    constructor(RNG _beaconRNG, RNG _blockhashRNG) public {
        beaconRNG = _beaconRNG;
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
        uint RN = beaconRNG.getRN(_block);

        if (RN == 0) {
            blockhashRNG.contribute(_block);
        } else {
            beaconRNG.contribute(_block);
        }
    }

    /**
     * @dev Get the random number.
     * @param _block Block the random number is linked to.
     * @return RN Random Number. If the number is not ready or has not been required 0 instead.
     */
    function getRN(uint _block) public returns (uint RN) {
        RN = beaconRNG.getRN(_block);

        // if beacon chain randomness is zero
        // fallback to blockhash RNG
        if (RN == 0) {
            RN = blockhashRNG.getRN(_block);
        }
    }
}