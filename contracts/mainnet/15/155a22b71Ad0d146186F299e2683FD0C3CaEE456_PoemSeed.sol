pragma solidity 0.8.12;
/**
@title Poem Seed Contract
*/
contract PoemSeed {
    /// @notice Collection Owner Address.
    address public constant collectionOwner = 0x8ba7E0BE0460035699BAddD1fD1aCCb178702348;
    
    /// @notice Mapping from nft id to the poem.
    mapping(uint => string) poem;

    /**
     * @notice Constructor
     * @param _poems Array of poems to linked with the nft's
     */
    constructor(string[11] memory _poems) {
        for(uint i=0; i<11; i++){
            poem[i] = _poems[i];
        }
    }

    /**
     * @notice Retreiving the poem by your token id
     * @param _id Nft id
     */
    function getSeedPoemById(uint _id) external view returns(string memory) {
        return poem[_id];
    }

}