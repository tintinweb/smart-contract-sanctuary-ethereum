// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import './params/Index.sol';


contract Genetics is Params {

    constructor(GeneticsConstructor.Struct memory input) Params(input) {}

    function wholeArithmeticRecombination(uint32[54] memory geneticSequence1, uint32[54] memory geneticSequence2) public view returns(uint32[54] memory geneticSequence) {
        
        // Return the average of parents genetical sequences
        for ( uint256 i = 2 ; i < 54 ; ++i ) {

            // arithmetic recombination
            geneticSequence[i] = ( geneticSequence1[i] + geneticSequence2[i] ) / 2;

            // Checks for resource id valability
            if ( geneticSequence[i] > control.maxValues[i] )
                geneticSequence[i] = 0;

        }

    }

    function swapMutation(uint32[54] memory geneticSequence, uint256 randomness) public view returns(uint32[54] memory) {

        // Generate random gene index
        uint256 randomGene = generateRandomGeneIndex(geneticSequence[2], randomness);
        
        // Generate random positions inside the gene
        (uint256 pos1, uint256 pos2) = generateRandomAlleles(geneticSequence,randomness,randomGene);

        // Swap allele
        uint32 aux = geneticSequence[pos2];
        geneticSequence[pos2] = geneticSequence[pos1];
        geneticSequence[pos1] = aux;

        return geneticSequence;
    }

    function inversionMutation(uint32[54] memory geneticSequence, uint256 randomness) public view returns(uint32[54] memory) {
        
        // Generate random gene index
        uint256 randomGene = generateRandomGeneIndex(geneticSequence[2], randomness);

        // Generate random positions inside the gene
        (uint256 pos1, uint256 pos2) = generateRandomAlleles(geneticSequence,randomness,randomGene);

        // Auxiliary variable
        uint32 aux;

        // Parse from pos1 to pos2
        for (uint i = pos1; i < pos1 + pos2 && pos1 + pos2 < geneticSequence.length ; ++i) {

            // Save allele on current index
            aux = geneticSequence[i];

            // Move the allele from "the end of [pos1,...,pos2] subarray" - i to current position
            geneticSequence[i] = geneticSequence[pos1 + pos2 - i];

            // Move the previously saved position into "the end of [pos1,...,pos2] subarray" - i position 
            geneticSequence[pos1 + pos2 - i] = geneticSequence[i];

        }

        return geneticSequence;
    }

    function scrambleMutation(uint32[54] memory geneticSequence, uint256 randomness) public view returns(uint32[54] memory) {
        
        // Generate random gene index
        uint256 randomGene = generateRandomGeneIndex(geneticSequence[2], randomness);

        // Generate random positions inside the gene
        (uint256 pos1, uint256 pos2) = generateRandomAlleles(geneticSequence,randomness,randomGene);
        
        // Auxiliary variable used to store one allele
        uint32 aux;

        // Auxiliary variable used to store the random position index, inside a gene
        uint256 pos;
        for (uint i = pos1; i < pos1 + pos2 && pos1 + pos2 < geneticSequence.length ; ++i) {

            // Generate a random position inside the gene, where pos1 <= pos <= pos2
            pos = (uint256(keccak256(abi.encodePacked(i, randomness))) % pos1) + pos2;

            // Save the allele of the random generated position inside the auxiliary variable
            aux = geneticSequence[pos];

            // Save the current allele into the random generated position allele
            geneticSequence[pos] = geneticSequence[i];

            // Save the random genenrated position allele into the current allele
            geneticSequence[i] = aux;

        }
        
        return geneticSequence;
    }
    
    function arithmeticMutation(uint32[54] memory geneticSequence, uint256 randomness) public view returns(uint32[54] memory) {

        // Generate random gene index
        uint256 randomGene = generateRandomGeneIndex(geneticSequence[2], randomness);

        // Generate random positions inside the gene
        (uint256 pos1, ) = generateRandomAlleles(geneticSequence,randomness,randomGene);

        uint256 randomValueToAdd = uint256(keccak256(abi.encodePacked(geneticSequence[15], randomness))) % control.maxValues[pos1];

        // Perform a incrementation
        geneticSequence[pos1] += uint32(randomValueToAdd);

        // Checks for resource id valability
        if ( geneticSequence[pos1] > control.maxValues[pos1] )
            geneticSequence[pos1] = 0;

        return geneticSequence;

    }

    function uniformCrossover(uint32[54] calldata geneticSequence1, uint32[54] calldata geneticSequence2, uint256 randomness) public view returns(uint32[54] memory geneticSequence) {
        for ( uint256 i = 0 ; i < 54 ; ++i ) {
            uint256 dominantGene = uint256(keccak256(abi.encodePacked(i, randomness)));
            if ( dominantGene % 100 < control.maleGenesProbability ) {
                geneticSequence[i] = geneticSequence1[i];
            } else {
                geneticSequence[i] = geneticSequence2[i];
            }
        }
    }

    function mixGenes(uint32[54] calldata geneticSequence1, uint32[54] calldata geneticSequence2, uint256 randomness) external view returns(uint32[54] memory) {

        // Performs the default uniform crossover algorithm
        uint32[54] memory geneticSequence = uniformCrossover(geneticSequence1,geneticSequence2,randomness);

        uint256 chance = randomness % 1000;
        if ( chance >= 444 && chance <= 446 ) {
            geneticSequence = inversionMutation(
                geneticSequence,
                randomness
            );
        }
        
        if ( chance >= 771 && chance <= 773 ) {
            geneticSequence = scrambleMutation(
                geneticSequence,
                randomness
            );
        }

        if ( chance < 5 ) {
            
            geneticSequence = swapMutation(
                geneticSequence,
                randomness
            );
            
        }

        if ( chance == 999 ) {
            geneticSequence = wholeArithmeticRecombination(
                uint256(keccak256(abi.encodePacked(block.timestamp, randomness, msg.sender))) % 2 == 0 ? geneticSequence1 : geneticSequence2,
                geneticSequence
            );
        }

        if ( chance == 312 ) {
            geneticSequence = arithmeticMutation(
                geneticSequence,
                randomness
            );
        }

        return geneticSequence;
    }

    function generateRandomGeneIndex(uint32 pillar, uint256 randomness) internal pure returns(uint256) {
        // Generate random gene index
        return ( uint256(keccak256(abi.encodePacked(pillar, randomness))) % 9 ) + 2;
    }

    function generateRandomAlleles(uint32[54] memory geneticSequence, uint256 randomness, uint256 randomGene) internal view returns(uint256,uint256) {

        // Generate 2 random indexes within the gene
        return(
            control.geneticSequenceSignature[randomGene] + (uint256(keccak256(abi.encodePacked(geneticSequence[6], randomness))) % 4),
            control.geneticSequenceSignature[randomGene] + (uint256(keccak256(abi.encodePacked(randomness, geneticSequence[10]))) % 4)
        );

    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '@openzeppelin/contracts/access/Ownable.sol';
import './Constructor.sol';


contract Params is Ownable {

    GeneticsConstructor.Struct public control;

    constructor(GeneticsConstructor.Struct memory input) {
        control = input;
    }

    function setGlobalParameters(GeneticsConstructor.Struct memory globalParameters) external {
        control = globalParameters;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


library GeneticsConstructor {
    
    struct Struct {
        address randomness;
        address terrains;
        uint32[54] male;
        uint32[54] female;
        uint32 maleGenesProbability;
        uint32 femaleGenesProbability;
        uint32[13] geneticSequenceSignature;
        uint32[54] maxValues;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}