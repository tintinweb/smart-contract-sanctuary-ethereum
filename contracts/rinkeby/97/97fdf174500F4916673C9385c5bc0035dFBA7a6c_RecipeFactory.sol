// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.7;

import './interfaces/IRecipeFactory.sol';
import './interfaces/IENS.sol';
import './Recipe.sol';

contract RecipeFactory is IRecipeFactory {
    /// @inheritdoc IRecipeFactory
    address public override owner;
    /// @inheritdoc IRecipeFactory
    address public override ens;

    /// @inheritdoc IRecipeFactory
    mapping(bytes32 => bool) public override ingredients;
    /// @inheritdoc IRecipeFactory
    mapping(bytes32 => address) public override recipes;
    mapping(bytes32 => bool) private verifier;

    modifier onlyOwner() {
        require(msg.sender == owner, '!owner');
        _;
    }

    constructor(bytes32[] memory _ingredients, address _ens) {
        owner = msg.sender;
        ens = _ens;
        for (uint i=0; i < _ingredients.length; i++){
            ingredients[_ingredients[i]] = true;
        }
    }

    /// @inheritdoc IRecipeFactory
    function setOwner(address _owner) external onlyOwner override {
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    /// @inheritdoc IRecipeFactory
    function makeRecipe(bytes32[] memory _ingredients) external override {
        require(_ingredients.length > 2 && _ingredients.length < 7, 'IIL'); // incorrect ingredient length
        quickSort(_ingredients, int(0), int(_ingredients.length - 1));
        bytes32 hash = 0;
        bool has = false;
        address _owner;
        for (uint i = 0; i < _ingredients.length; i++) {
            require(ingredients[_ingredients[i]], '!I'); // not an ingredient
            require(!verifier[_ingredients[i]], 'DI'); // duplicate ingredient
            hash = keccak256(abi.encode(_ingredients[i], hash));
            verifier[_ingredients[i]] = true;
            _owner = ENS(ens).owner(_ingredients[i]);
            has = has || _owner == msg.sender;
        }
        require(has, '!IO'); // not ingredient owner
        require(recipes[hash] == address(0), 'DR'); // duplicate recipe
        clean(_ingredients);
        recipes[hash] = address(new Recipe{salt : hash}(_ingredients, ens));
        emit RecipeCreated(_ingredients);
    }

    /// @inheritdoc IRecipeFactory
    function addIngredient(bytes32 ingredient) external onlyOwner override {
        require(!ingredients[ingredient], 'AI'); // already ingredient
        ingredients[ingredient] = true;
        emit IngredientCreated(ingredient);
    }

    function clean(bytes32[] memory _ingredients) internal {
        for (uint i = 0; i < _ingredients.length; i++) {
            delete verifier[_ingredients[i]];
        }
    }

    function quickSort(bytes32[] memory arr, int left, int right) internal{
        int i = left;
        int j = right;
        if(i==j) return;
        bytes32 pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.7;

/// @title The interface for the RecipeFactory
/// @notice The Recipe Factory allows new recipes to be deployed
interface IRecipeFactory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a recipe is created
    /// @param ingredients The ingredients needed for the recipe
    event RecipeCreated(
        bytes32[] indexed ingredients
    );

    /// @notice Emitted when an ingredient is created
    /// @param ingredient The new ingredient
    event IngredientCreated(
        bytes32 ingredient
    );

    /// @notice Returns a true if ingredient is accepted
    /// @param key The byte32 representation of the ingredient
    /// @return True if ingredient is valid, false otherwise
    function ingredients(bytes32 key) external view returns (bool);

    /// @notice Returns the recipe's address
    /// @param key The byte32 representation of the recipe
    /// @return The address of the recipe
    function recipes(bytes32 key) external view returns (address);

    /// @notice Returns the contract owner
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the ens contract
    /// @return The address of the ens contract
    function ens() external view returns (address);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Creates a new recipe
    /// @param ingredients The ingredients for the recipe
    function makeRecipe(bytes32[] memory ingredients) external;

    /// @notice Add an ingredient
    /// @param name The name of the recipe
    function addIngredient(bytes32 name) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.7;

abstract contract ENS {
    function owner(bytes32 node) external virtual view returns (address);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.7;

import './interfaces/IRecipe.sol';
import './interfaces/IENS.sol';

contract Recipe is IRecipe {
    /// @inheritdoc IRecipe
    bytes32[] public override ingredientList;
    /// @inheritdoc IRecipe
    mapping(bytes32 => address) public override ingredientOwner;
    // @inheritdoc IRecipe
    mapping(bytes32 => bool) public override ingredients;
    // @inheritdoc IRecipe
    uint8 public override ingredientAmount;
    // @inheritdoc IRecipe
    uint8 public override ingredientCounter;
    // @inheritdoc IRecipe
    bool public override isFinished;
    // @inheritdoc IRecipe
    address public override ens;

    constructor(bytes32[] memory _ingredients, address _ens) {
        ingredientList = _ingredients;
        for (uint256 i = 0; i < _ingredients.length; i++) {
            ingredients[_ingredients[i]] = true;
        }
        ens = _ens;
        ingredientAmount = uint8(_ingredients.length);
    }

    // @inheritdoc IRecipe
    function addIngredient(bytes32 ingredient) external override{
        require(ingredientOwner[ingredient] == address(0), 'DI'); // duplicate ingredient
        require(ingredients[ingredient], '!I'); // not ingredient
        address _owner = ENS(ens).owner(ingredient);
        require(msg.sender == _owner, '!owner'); // not owner

        ingredientOwner[ingredient] = msg.sender;
        ingredientCounter++;
        emit IngredientAdded(ingredient, msg.sender);

        if (ingredientCounter == ingredientAmount) {
            isFinished = true;
            emit RecipeCompleted();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface IRecipe {
    event RecipeCompleted();
    event IngredientAdded(bytes32 ingredient, address owner);

    /// @notice Returns the amount of ingredients in the recipe
    /// @return The amount of ingredients in the recipe
    function ingredientAmount() external view returns(uint8);

    /// @notice Returns the counter of ingredients cooked
    /// @return The counter of ingredients cooked
    function ingredientCounter() external view returns(uint8);

    /// @notice Returns the ens contract address
    /// @return The ens contract address
    function ens() external view returns (address);

    /// @notice Returns the state of the recipe
    /// @return True if the recipe is finished
    function isFinished() external view returns (bool);

    /// @notice Returns the ingredient at index
    /// @param index The index
    /// @return The ingredient at index
    function ingredientList(uint index) external view returns(bytes32);

    /// @notice Returns the address of the ingredient owner
    /// @param ingredient The ingredient
    /// @return The address of the ingredient owner
    function ingredientOwner(bytes32 ingredient) external view returns(address);

    /// @notice Returns true if ingredient is part of the recipe
    /// @param ingredient The ingredient
    /// @return True if ingredient is part of the recipe
    function ingredients(bytes32 ingredient) external view returns(bool);

    /// @notice Add an ingredient to the recipe
    /// @param ingredient The ingredient to add
    function addIngredient(bytes32 ingredient) external;
}