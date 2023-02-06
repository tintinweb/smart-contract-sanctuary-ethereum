// SPDX-License-Identifier: MIT

pragma solidity >=0.8.17;

import "./PixieJarsStoriesStructs.sol";
import "./IPixieJarsStories.sol";
import "./IPixieDust.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/** @title Pixie Jars Stories - Minter Contract
 *  @author 0xjustadev/0xth0mas
 *  @notice This contract is used to set minting recipes for token minting.
 *          Recipes can include payment in ETH, Pixie Dust and/or other
            tokens within the Pixie Jars Stories collection to mint a new token.
 */
contract PixieJarsStoriesMinter is Ownable {

    error ArrayLengthMismatch();
    error InvalidRecipe();
    error InvalidRecipeUsage();
    error RecipeNotActive();
    error InsufficientPayment();

    MintRecipe[] private recipes;
    mapping(bytes32 => bool) private validRecipe;
    IPixieJarsStories public pixieJarsStories;
    IPixieDust public pixieDust;

    constructor(address _pixieJarsStories, address _pixieDust) {
        pixieJarsStories = IPixieJarsStories(_pixieJarsStories);
        pixieDust = IPixieDust(_pixieDust);
    }
    
    /**
     *   @dev mint function takes a given recipe, multiplier and user's proposed mint/burn token amounts
     *        and validates that it is a valid recipe and all parameters of the recipe are being followed.
     *        If the recipe is being followed, the token contract is called to mint and burn the specified
     *        tokens.
     */
    function mint(MintRecipe calldata recipe, uint256 recipeMultiplier, uint32 pixieDustCost, uint256[] calldata mintTokenIds, uint256[] calldata mintTokenQuantities, 
        uint256[] calldata burnTokenIds, uint256[] calldata burnTokenQuantities) external payable {

        //check recipe hash to ensure it is valid
        bytes32 recipeHash = keccak256(abi.encode(recipe));
        if(!validRecipe[recipeHash]) { revert InvalidRecipe(); }

        //check recipe to ensure it is active
        if(recipe.startTime > block.timestamp) { revert RecipeNotActive(); }
        if(recipe.endTime < block.timestamp) { revert RecipeNotActive(); }

        //validate array lengths match
        if(mintTokenIds.length != mintTokenQuantities.length) { revert ArrayLengthMismatch(); }
        if(burnTokenIds.length != burnTokenQuantities.length) { revert ArrayLengthMismatch(); }
        if(recipe.mintTokenIds.length != mintTokenIds.length) { revert InvalidRecipeUsage(); }
        if(recipe.burnTokenIds.length != burnTokenIds.length) { revert InvalidRecipeUsage(); }

        //check mint ids/quantities for compliance with recipe
        for(uint256 i = 0;i < mintTokenIds.length;) {
            if(recipe.mintTokenIds[i] != mintTokenIds[i]) { revert InvalidRecipeUsage(); }
            if((recipe.mintTokenQuantities[i] * recipeMultiplier) != mintTokenQuantities[i]) { revert InvalidRecipeUsage(); }
            unchecked {
                ++i;
            }
        }

        //check burn ids/quantities for compliance with recipe
        for(uint256 i = 0;i < burnTokenIds.length;) {
            if(recipe.burnTokenIds[i] != burnTokenIds[i]) { revert InvalidRecipeUsage(); }
            if((recipe.burnTokenQuantities[i] * recipeMultiplier) != burnTokenQuantities[i]) { revert InvalidRecipeUsage(); }
            unchecked {
                ++i;
            }
        }

        //check pixie dust to burn for compliance with recipe
        if(recipe.pixieDustCost > 0) {
            if((recipe.pixieDustCost * recipeMultiplier) != pixieDustCost) { revert InvalidRecipeUsage(); }
            uint256 totalPixieDustCost = uint256(pixieDustCost) * 10**18;
            pixieDust.burnDust(msg.sender, totalPixieDustCost);
        }

        //calculate mint cost, refund if overpayment sent
        uint256 totalCost = uint256(recipe.cost) * 1 gwei * recipeMultiplier;
        refundIfOver(totalCost);

        //single token mint if token id length is 1, batch mint if more than 1
        if(mintTokenIds.length == 1) {
            pixieJarsStories.mint(msg.sender, mintTokenIds[0], mintTokenQuantities[0]);
        } else if(mintTokenIds.length > 1) {
            pixieJarsStories.mintBatch(msg.sender, mintTokenIds, mintTokenQuantities);
        }

        //single token burn if token id length is 1, batch mint if more than 1
        if(burnTokenIds.length == 1) {
            pixieJarsStories.burn(msg.sender, burnTokenIds[0], burnTokenQuantities[0]);
        } else if(burnTokenIds.length > 1) {
            pixieJarsStories.burnBatch(msg.sender, burnTokenIds, burnTokenQuantities);
        }
    }

    /**
     *   @dev returns an array of active recipes that can be submitted for minting
     */
    function getActiveRecipes() external view returns(MintRecipe[] memory activeRecipes) {
        MintRecipe[] memory tmpRecipes = new MintRecipe[](recipes.length);
        uint256 activeCount;
        bytes32 recipeHash;
        for(uint256 i = 0;i < recipes.length;) {
            MintRecipe memory tmpRecipe = recipes[i];
            if(tmpRecipe.startTime < block.timestamp) {
                if(tmpRecipe.endTime > block.timestamp) {
                    recipeHash = keccak256(abi.encode(tmpRecipe));
                    if(validRecipe[recipeHash]) {
                        tmpRecipes[activeCount] = tmpRecipe;
                        unchecked {
                            activeCount++;
                        }
                    }
                }
            }
            unchecked {
                ++i;
            }
        }
        
        activeRecipes = new MintRecipe[](activeCount);
        for(uint256 i = 0;i < activeCount;) {
            activeRecipes[i] = tmpRecipes[i];
            unchecked {
                ++i;
            }
        }
    }    

    /**
     *   @dev Administrative function to add a new recipe to define token minting and burning parameters, time window and costs
     */
    function addRecipe(uint32 cost, uint32 startTime, uint32 endTime, uint32 pixieDustCost, uint256[] calldata mintTokenIds,
        uint256[] calldata mintTokenQuantities, uint256[] calldata burnTokenIds, uint256[] calldata burnTokenQuantities) external onlyOwner {
        if(mintTokenIds.length != mintTokenQuantities.length) { revert ArrayLengthMismatch(); }
        if(burnTokenIds.length != burnTokenQuantities.length) { revert ArrayLengthMismatch(); }
        if(mintTokenIds.length == 0 && burnTokenIds.length == 0) { revert InvalidRecipe(); }

        MintRecipe memory newRecipe;

        newRecipe.cost = cost;
        newRecipe.startTime = startTime;
        newRecipe.endTime = endTime;
        newRecipe.pixieDustCost = pixieDustCost;
        newRecipe.mintTokenIds = mintTokenIds;
        newRecipe.mintTokenQuantities = mintTokenQuantities;
        newRecipe.burnTokenIds = burnTokenIds;
        newRecipe.burnTokenQuantities = burnTokenQuantities;

        bytes32 recipeHash = keccak256(abi.encode(newRecipe));
        validRecipe[recipeHash] = true;
        recipes.push(newRecipe);
    }

    /**
     *   @dev Administrative function to enable and disable a recipe if necessary outside of its time limit settings
     */
    function setRecipeValid(MintRecipe calldata recipe, bool valid) external onlyOwner {
        bytes32 recipeHash = keccak256(abi.encode(recipe));
        validRecipe[recipeHash] = valid;
    }

    /**
     *   @dev If msg.value exceeds calculated payment for mint transaction, refunds the overage back to msg.sender
     */
    function refundIfOver(uint256 price) private {
        if(msg.value < price) { revert InsufficientPayment(); }
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    /**
     *   @dev Withdraws minting funds from contract
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
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

pragma solidity ^0.8.0;

interface IPixieDust {
    function burnDust(address from, uint256 amount) external;
    function mintDust(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPixieJarsStories {

    error UnauthorizedMinter();

    function mint(address to, uint256 id, uint256 amount) external;
    function mintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts) external;
    function burn(address from, uint256 burnId, uint256 burnAmount) external;
    function burnBatch(address from, uint256[] calldata burnIds, uint256[] calldata burnAmounts) external;
    function setAllowedMinter(address minter, bool allowed) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct MintRecipe {
    uint32 cost; //in GWEI
    uint32 startTime;
    uint32 endTime;
    uint32 pixieDustCost;
    uint256[] mintTokenIds;
    uint256[] mintTokenQuantities;
    uint256[] burnTokenIds;
    uint256[] burnTokenQuantities;
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