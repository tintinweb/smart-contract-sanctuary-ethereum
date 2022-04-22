/**
 *Submitted for verification at Etherscan.io on 2022-04-22
*/

pragma solidity 0.8.12;

/**
@title Poem Seed Registry Contract
*/
contract SeedPoem {
    /// @notice Mapping from nft id to the poem.
    mapping(uint => string) poem;

    /**
     * @notice Constructor
     * @param _poems Array of poems to linked with the nft's
     */
    constructor(string[] memory _poems) {
        for(uint i = 0; i < _poems.length; i++) {
           poem[i] = _poems[i];
        }
    }

    /**
     * @notice Retreiving the poem by id
     * @param _id Nft id
     */
    function getSeedPoemById(uint _id) external view returns(string memory) {
        return poem[_id];
    }

}