/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: contracts/RandomNasAcademySVG.sol


pragma solidity ^0.8.10;


contract OnChainSVG is Ownable {
    struct Layer {
        string name;
        string base64Svg;
    }

    struct LayerInput {
        string name;
        string base64Svg;
        uint8 layerIndex;
        uint8 itemIndex;
    }

    /**
     * Layers in order:
     * 0. Background (9)
     * 1. Skin (3)
     * 2. Footwear (4)
     * 3. Bottom (8)
     * 4. Top (7)
     * 5. Glasses (3)
     * 6. Hair (7)
     * 7. Headwear (4)
     * 8. Curious Addy (8)
     */
    uint256 public constant NUM_LAYERS = 9;

    mapping(uint256 => Layer) [NUM_LAYERS] layers;

    uint16[][NUM_LAYERS] WEIGHTS;

    constructor() {
        // Backgrounds (9)
        WEIGHTS[0] = [3000, 2000, 2000, 1400, 500, 500, 250, 250, 100];
        // Skin (3)
        WEIGHTS[1] = [3333, 3333, 3334];
        // Footwear (4)
        WEIGHTS[2] = [5000, 2500, 2000, 500];
        // Bottom (8)
        WEIGHTS[3] = [3000, 2000, 2000, 1650, 500, 500, 250, 100];
        // Top (7)
        WEIGHTS[4] = [4000, 2000, 2000, 1150, 500, 250, 100];
        // Glasses (3 + 1 for none [last])
        WEIGHTS[5] = [2500, 2000, 500, 5000];
        // Hair (7)
        WEIGHTS[6] = [4000, 2000, 2000, 1150, 500, 250, 100];
        // Headwear (4 + 1 for none [last])
        WEIGHTS[7] = [2500, 1900, 500, 100, 5000];
        // Curious Addy (8)
        WEIGHTS[8] = [3000, 2000, 2000, 1650, 500, 500, 250, 100];
    }

    // this lets us input the SVG data we need
    function setLayers(
        uint256 layerCount,
        string[] calldata names,
        string[] calldata base64Svgs,
        uint256[] calldata layerIndexes,
        uint256[] calldata itemIndexes
    ) external onlyOwner {
        for (uint16 i = 0; i < layerCount; i++) {
            layers[layerIndexes[i]][itemIndexes[i]] = Layer(names[i], base64Svgs[i]);
        }
    }

    function getLayer(uint8 layerIndex, uint8 itemIndex) public view returns (Layer memory) {
        return layers[layerIndex][itemIndex];
    }

    // This splits the DNA, a random number generated by Chainlink VRF, into NUM_LAYERS number of random numbers between 0 to 10,000
    function splitNumber(uint256 _number) internal pure returns (uint16[NUM_LAYERS] memory numbers) {
        for (uint256 i = 0; i < numbers.length; i++) {
            // means the number will be always less than 10,000, for use with the weights indexing in the next step
            numbers[i] = uint16(_number % 10000);
            // this modifies the base random number as a shift operator, equivalent to _number / 2**14, aka shifting the number of binary bits over by 14 times, which is very strange hmm as per https://ethereum.stackexchange.com/questions/94675/what-does-the-operator-do-in-solidity
            // Base DNA in ChainRunners looks like this, fascinating: 103081089982373387917516143957755319387957419765940801994810980124138188719328
            // figure out more how this works but if this doesn't work, just replace it by some other pseudorandom method for splitting one random number into multiple random numbers, maybe something like this:
            _number = uint256(keccak256(abi.encodePacked(_number % 10000, i)));
            // _number >>= 14;
        }
        return numbers;
    }

    function getTokenData(uint256 _dna) public view returns (Layer [NUM_LAYERS] memory tokenLayers, uint8 numTokenLayers) {
        uint16[NUM_LAYERS] memory dna = splitNumber(_dna);

        // find the right layer for each layer
        for (uint8 i = 0; i < NUM_LAYERS; i++) {
            Layer memory layer = layers[i][getLayerIndex(dna[i], i)];
            if (bytes(layer.base64Svg).length > 0) {
                // starts at 0 and goes up
                tokenLayers[numTokenLayers] = layer;
                // base64 encoded attribute names for each layer, e.g. "Background", "Hair", etc.
                // traitTypes[numTokenLayers] = ["QmFja2dyb3VuZCAg","UmFjZSAg","RmFjZSAg","TW91dGgg","Tm9zZSAg","RXllcyAg","RWFyIEFjY2Vzc29yeSAg","RmFjZSBBY2Nlc3Nvcnkg","TWFzayAg","SGVhZCBCZWxvdyAg","RXllIEFjY2Vzc29yeSAg","SGVhZCBBYm92ZSAg","TW91dGggQWNjZXNzb3J5"][i];
                numTokenLayers++;
            }
        }
        return (tokenLayers, numTokenLayers);
    }

    function tokenSVG(uint256 _dna) public view returns (string memory) {
        (Layer [NUM_LAYERS] memory tokenLayers, uint8 numTokenLayers) = getTokenData(_dna);
        string memory compositeSvg;
        for (uint8 i = 0; i < numTokenLayers; i++) {
            compositeSvg = string(abi.encodePacked(compositeSvg, tokenLayers[i].base64Svg));
        }
        return string(abi.encodePacked(
                "PHN2ZyB3aWR0aD0iNzIxIiBoZWlnaHQ9IjcyMSIgdmlld0JveD0iMCAwIDcyMSA3MjEiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+",
                compositeSvg,
                "PC9zdmc+"
            )
        );
    }

    function getLayerIndex(uint16 _dna, uint8 _index) public view returns (uint) {
        uint16 lowerBound;
        uint16 percentage;
        // lowerBound and percentage start at 0, percentage is the current amount, then DNA is a number between 0 and 10000
        for (uint8 i; i < WEIGHTS[_index].length; i++) {
            percentage = WEIGHTS[_index][i];
            if (_dna >= lowerBound && _dna < lowerBound + percentage) {
                return i;
            }
            lowerBound += percentage;
        }
        // If not found, return index higher than available layers.  Will get filtered out.
        return WEIGHTS[_index].length;
    }

}