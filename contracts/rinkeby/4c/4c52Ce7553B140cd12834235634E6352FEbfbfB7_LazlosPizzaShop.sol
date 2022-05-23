// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/Strings.sol";

import './Types/Types.sol';

/*
   __           _      _        ___ _                __ _                 
  / /  __ _ ___| | ___( )__    / _ (_)__________ _  / _\ |__   ___  _ __  
 / /  / _` |_  / |/ _ \/ __|  / /_)/ |_  /_  / _` | \ \| '_ \ / _ \| '_ \ 
/ /__| (_| |/ /| | (_) \__ \ / ___/| |/ / / / (_| | _\ \ | | | (_) | |_) |
\____/\__,_/___|_|\___/|___/ \/    |_/___/___\__,_| \__/_| |_|\___/| .__/ 
                                                                   |_|    

LazlosPizzaShop is the main contract for buying ingredients and baking pizza's out of Lazlo's kitchen.
*/
contract LazlosPizzaShop is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;
    using Strings for uint256;

    bool public mintingOn = true;
    bool public bakeRandomPizzaOn = true;
    uint256 public bakePizzaPrice = 0.01 ether;
    uint256 public unbakePizzaPrice = 0.05 ether;
    uint256 public rebakePizzaPrice = 0.01 ether;
    uint256 public randomBakePrice = 0.05 ether;
    address public pizzaContractAddress;
    address public ingredientsContractAddress;
    address private systemAddress;
    mapping(address => uint256) artistWithdrawalAmount;
    mapping(uint256 => mapping(address => bool)) isPaidByBlockAndAddress;

    function setMintingOn(bool on) public onlyOwner {
        mintingOn = on;
    }

    function setBakeRandomPizzaOn(bool on) public onlyOwner {
        bakeRandomPizzaOn = on;
    }

    function setPizzaContractAddress(address addr) public onlyOwner {
        pizzaContractAddress = addr;
    }

    function setIngredientsContractAddress(address addr) public onlyOwner {
        ingredientsContractAddress = addr;
    }
    
    function setSystemAddress(address addr) public onlyOwner {
        systemAddress = addr;
    }

    function buyIngredients(uint256[] memory tokenIds, uint256[] memory amounts) public payable nonReentrant {
        require(mintingOn, 'minting must be on');
        
        uint256 expectedPrice;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 amount = amounts[i];

            Ingredient memory ingredient = ILazlosIngredients(ingredientsContractAddress).getIngredient(tokenId);
            require(bytes(ingredient.name).length != 0, 'Ingredient does not exist');
            require(ingredient.supply >= amount, 'Not enough ingredient leftover.');

            ILazlosIngredients(ingredientsContractAddress).decreaseIngredientSupply(tokenId, amount);

            unchecked {
                expectedPrice += ingredient.price * amount;
            }
        }
        
        require(expectedPrice == msg.value, 'Invalid price.');

        ILazlosIngredients(ingredientsContractAddress).mintIngredients(msg.sender, tokenIds, amounts);
    }

    function bakePizza(uint256[] memory tokenIds) public payable nonReentrant returns (uint256) {
        require(mintingOn, 'minting must be on');
        require(msg.value == bakePizzaPrice, 'Invalid price.');
        return _bakePizza(tokenIds, true);
    }

    function buyAndBakePizza(uint256[] memory tokenIds) public payable nonReentrant returns (uint256) {
        require(mintingOn, 'minting must be on');

        // Validate that:
        //  1. None of these ingredients are sold out.
        //  2. The given eth is correct (cost of ingredients + bake price).
        uint256 expectedPrice = bakePizzaPrice;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            Ingredient memory ingredient = ILazlosIngredients(ingredientsContractAddress).getIngredient(tokenId);
            require(ingredient.supply >= 1, 'Ingredient sold out.');

            ILazlosIngredients(ingredientsContractAddress).decreaseIngredientSupply(tokenId, 1);

            unchecked {
                expectedPrice += ingredient.price;
            }
        }

        require(expectedPrice == msg.value, 'Invalid price.');
        return _bakePizza(tokenIds, false);
    }
    
    struct NumIngredientsUsed {
        uint16 cheeses;
        uint16 meats;
        uint16 toppings;
    }

    function _bakePizza(uint256[] memory tokenIds, bool useBuyersIngredients) private returns (uint256) {
        Pizza memory pizza;
        return _addIngredientsToPizza(0, pizza, tokenIds, useBuyersIngredients);
    }

    function _addIngredientsToPizza(
        uint256 pizzaTokenId,
        Pizza memory pizza,
        uint256[] memory tokenIds,
        bool useBuyersIngredients
    ) private returns (uint256) {
        // Calculate num ingredients already used in the pizza if its not a fresh bake.
        NumIngredientsUsed memory numIngredientsUsed;

        if (pizzaTokenId != 0) {
            for (uint256 i; i<pizza.cheeses.length;) {
                if (pizza.cheeses[i] == 0) {
                    break;
                }

                unchecked {
                    numIngredientsUsed.cheeses++;
                    i++;
                }
            }

            for (uint256 i; i<pizza.meats.length;) {
                if (pizza.meats[i] == 0) {
                    break;
                }

                unchecked {
                    numIngredientsUsed.meats++;
                    i++;
                }
            }

            for (uint256 i; i<pizza.toppings.length;) {
                if (pizza.toppings[i] == 0) {
                    break;
                }

                unchecked {
                    numIngredientsUsed.toppings++;
                    i++;
                }
            }
        }
        
        // Loop over each token and:
        //  1. Check that the buyer has the correct balance for each ingredient (if useBuyersIngredients is true).
        //  2. Collect the ingredients and validate that the correct amount of each ingredient is being used:
        //      - 1 Base
        //      - 1 Sauce
        //      - 1-3 Cheeses
        //      - 0-4 Meats
        //      - 0-4 Toppings
        uint256[] memory amounts = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];

            if (useBuyersIngredients) {
                uint256 balance = ILazlosIngredients(ingredientsContractAddress).balanceOfAddress(msg.sender, tokenId);
                require(balance > 0, 'Missing ingredient.');
            }
            
            Ingredient memory ingredient = ILazlosIngredients(ingredientsContractAddress).getIngredient(tokenId);
            
            if (ingredient.ingredientType == IngredientType.Base) {
                require(pizza.base == 0, 'Cannot use more than 1 base.');

                pizza.base = uint16(tokenId);
            
            } else if (ingredient.ingredientType == IngredientType.Sauce) {
                require(pizza.sauce == 0, 'Cannot use more than 1 sauce.');

                pizza.sauce = uint16(tokenId);
            
            } else if (ingredient.ingredientType == IngredientType.Cheese) {
                unchecked {
                    numIngredientsUsed.cheeses++;
                }
                
                require(numIngredientsUsed.cheeses <= 3, 'Cannot use more than 3 cheeses.');
                
                pizza.cheeses[numIngredientsUsed.cheeses - 1] = uint16(tokenId);
            
            } else if (ingredient.ingredientType == IngredientType.Meat) {
                unchecked {
                    numIngredientsUsed.meats++;
                }
                
                require(numIngredientsUsed.meats <= 4, 'Cannot use more than 4 meats.');
                
                pizza.meats[numIngredientsUsed.meats - 1] = uint16(tokenId);

            } else if (ingredient.ingredientType == IngredientType.Topping) {
                unchecked {
                    numIngredientsUsed.toppings++;
                }
                
                require(numIngredientsUsed.toppings <= 4, 'Cannot use more than 4 toppings.');
                
                pizza.toppings[numIngredientsUsed.toppings - 1] = uint16(tokenId);
            
            } else {
                revert('Invalid ingredient type.');
            }

            amounts[i] = 1;

            unchecked {
                i++;
            }
        }

        require(pizza.base != 0, 'A base is required.');
        require(pizza.sauce != 0, 'A sauce is required.');
        require(pizza.cheeses[0] != 0, 'At least one cheese is required.');
        validateNoDuplicateIngredients(pizza);

        // Make sure to burn buyer's ingredients.
        if (useBuyersIngredients) {
            ILazlosIngredients(ingredientsContractAddress).burnIngredients(msg.sender, tokenIds, amounts);
        }

        if (pizzaTokenId == 0) {
            // Now we mint a new pizza.
            return ILazlosPizzas(pizzaContractAddress).bake(msg.sender, pizza);
        
        } else {
            // Rebake pizza now.
            ILazlosPizzas(pizzaContractAddress).rebake(msg.sender, pizzaTokenId, pizza);
            return pizzaTokenId;
        }
    }

    function validateNoDuplicateIngredients(Pizza memory pizza) internal pure {
        validateNoDuplicates3(pizza.cheeses);
        validateNoDuplicates4(pizza.meats);
        validateNoDuplicates4(pizza.toppings);
    }

    function validateNoDuplicates3(uint16[3] memory arr) internal pure {
        for (uint256 i; i<arr.length;) {
            if (arr[i] == 0) {
                break;
            }

            for (uint256 j; j<arr.length;) {
                if (arr[j] == 0) {
                    break;
                }

                if (i == j) {
                    unchecked {
                        j++;
                    }
                    continue;
                }

                require(arr[i] != arr[j], 'No duplicate ingredients.');      

                unchecked {
                    j++;
                }
            }

            unchecked {
                i++;
            }
        }
    }

    function validateNoDuplicates4(uint16[4] memory arr) internal pure {
        for (uint256 i; i<arr.length;) {
            if (arr[i] == 0) {
                break;
            }

            for (uint256 j; j<arr.length;) {
                if (arr[j] == 0) {
                    break;
                }

                if (i == j) {
                    unchecked {
                        j++;
                    }
                    continue;
                }

                require(arr[i] != arr[j], 'No duplicate ingredients.');      

                unchecked {
                    j++;
                }
            }

            unchecked {
                i++;
            }
        }
    }

    function unbakePizza(uint256 pizzaTokenId) public payable nonReentrant {
        require(mintingOn, 'minting must be on');
        require(msg.value == unbakePizzaPrice, 'Invalid price.');

        Pizza memory pizza = ILazlosPizzas(pizzaContractAddress).pizza(pizzaTokenId);

        // Sum up the number of ingredients in this pizza.
        // Every pizza has at least 3 ingredients.
        uint256 numIngredientsInPizza = 3;
        for (uint256 i=1; i<3;) {
            if (pizza.cheeses[i] == 0) {
                break;
            }

            numIngredientsInPizza++;

            unchecked {
                i++;
            }
        }

        for (uint256 i; i<4;) {
            if (pizza.meats[i] == 0) {
                break;
            }

            numIngredientsInPizza++;

            unchecked {
                i++;
            }
        }

        for (uint256 i; i<4;) {
            if (pizza.toppings[i] == 0) {
                break;
            }

            numIngredientsInPizza++;

            unchecked {
                i++;
            }
        }

        // Build up tokenIds array.
        uint256[] memory tokenIds = new uint256[](numIngredientsInPizza);
        tokenIds[0] = uint256(pizza.base);
        tokenIds[1] = uint256(pizza.sauce);
        uint256 tokenIdsIndex = 2;

        for (uint256 i=0; i<3;) {
            if (pizza.cheeses[i] == 0) {
                break;
            }

            tokenIds[tokenIdsIndex] = pizza.cheeses[i];
            unchecked {
                tokenIdsIndex++;
                i++;
            }
        }

        for (uint256 i; i<4;) {
            if (pizza.meats[i] == 0) {
                break;
            }

            tokenIds[tokenIdsIndex] = pizza.meats[i];
            unchecked {
                tokenIdsIndex++;
                i++;
            }
        }

        for (uint256 i; i<4;) {
            if (pizza.toppings[i] == 0) {
                break;
            }

            tokenIds[tokenIdsIndex] = pizza.toppings[i];
            unchecked {
                tokenIdsIndex++;
                i++;
            }
        }

        // Create amounts array which is just a bunch of 1's.
        uint256[] memory amounts = new uint256[](numIngredientsInPizza);
        for (uint256 i; i<numIngredientsInPizza;) {
            amounts[i] = 1;

            unchecked {
                i++;
            }
        }

        ILazlosIngredients(ingredientsContractAddress).mintIngredients(msg.sender, tokenIds, amounts);
        ILazlosPizzas(pizzaContractAddress).burn(pizzaTokenId);
    }

    function rebakePizza(uint256 pizzaTokenId, uint256[] memory ingredientTokenIdsToAdd, uint256[] memory ingredientTokenIdsToRemove) public payable nonReentrant {
        require(mintingOn, 'minting must be on');
        require(msg.value == rebakePizzaPrice, 'Invalid price.');

        Pizza memory pizza = ILazlosPizzas(pizzaContractAddress).pizza(pizzaTokenId);

        // Loop over ingredients to be removed from pizza and update the pizza accordingly.
        for (uint256 i; i<ingredientTokenIdsToRemove.length;) {
            uint256 tokenIdToRemove = ingredientTokenIdsToRemove[i];

            Ingredient memory ingredient = ILazlosIngredients(ingredientsContractAddress).getIngredient(tokenIdToRemove);

            if (ingredient.ingredientType == IngredientType.Base) {
                pizza.base = 0;
            
            } else if (ingredient.ingredientType == IngredientType.Sauce) {
                pizza.sauce = 0;
            
            } else if (ingredient.ingredientType == IngredientType.Cheese) {
                bool foundCheese;
                uint16[3] memory updatedCheeses;
                uint256 updatedCheeseIndex;
                for (uint256 j; j<updatedCheeses.length;) {
                    uint256 existingCheese = pizza.cheeses[j];
                    if (existingCheese == 0) {
                        break;
                    }

                    if (existingCheese != tokenIdToRemove) {
                        updatedCheeses[updatedCheeseIndex] = uint16(existingCheese);

                        unchecked {
                            updatedCheeseIndex++;
                        }
                    
                    } else {
                        foundCheese = true;
                    }

                    unchecked {
                        j++;
                    }
                }

                require(foundCheese, 'Could not find cheese to be removed.');
                pizza.cheeses = updatedCheeses;
            
            } else if (ingredient.ingredientType == IngredientType.Meat) {
                bool foundMeat;
                uint16[4] memory updatedMeats;
                uint256 updatedMeatIndex;
                for (uint256 j; j<updatedMeats.length;) {
                    uint256 existingMeat = pizza.meats[j];
                    if (existingMeat == 0) {
                        break;
                    }

                    if (existingMeat != tokenIdToRemove) {
                        updatedMeats[updatedMeatIndex] = uint16(existingMeat);

                        unchecked {
                            updatedMeatIndex++;
                        }
                    
                    } else {
                        foundMeat = true;
                    }

                    unchecked {
                        j++;
                    }
                }

                require(foundMeat, 'Could not find meat to be removed.');
                pizza.meats = updatedMeats;

            } else if (ingredient.ingredientType == IngredientType.Topping) {
                bool foundTopping;
                uint16[4] memory updatedToppings;
                uint256 updatedToppingIndex;
                for (uint256 j; j<updatedToppings.length;) {
                    uint256 existingTopping = pizza.toppings[j];
                    if (existingTopping == 0) {
                        break;
                    }

                    if (existingTopping != tokenIdToRemove) {
                        updatedToppings[updatedToppingIndex] = uint16(existingTopping);

                        unchecked {
                            updatedToppingIndex++;
                        }
                    
                    } else {
                        foundTopping = true;
                    }

                    unchecked {
                        j++;
                    }
                }

                require(foundTopping, 'Could not find topping to be removed.');
                pizza.toppings = updatedToppings;
            
            } else {
                revert('Invalid ingredient type.');
            }

            unchecked {
                i++;
            }
        } 

        _addIngredientsToPizza(pizzaTokenId, pizza, ingredientTokenIdsToAdd, true);
    }

    function bakeRandomPizza(uint256[] memory tokenIds, uint256 timestamp, bytes32 r, bytes32 s, uint8 v) public payable nonReentrant returns (uint256) {
        require(mintingOn, 'minting must be on');
        require(bakeRandomPizzaOn, 'bakeRandomPizza must be on');
        require(randomBakePrice == msg.value, 'Invalid price.');
        require(block.timestamp - timestamp < 300, 'timestamp expired');

        bytes32 messageHash = keccak256(abi.encodePacked(
            msg.sender,
            timestamp,
            tokenIds
        ));

        address signerAddress = verifySignature(messageHash, r, s, v);
        bool validSignature = signerAddress == systemAddress;
        require(validSignature, 'Invalid signature.');

        // Validate that:
        //  1. None of these ingredients are sold out.
        uint256 expectedPrice = bakePizzaPrice;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            Ingredient memory ingredient = ILazlosIngredients(ingredientsContractAddress).getIngredient(tokenId);
            require(ingredient.supply >= 1, 'Ingredient sold out.');

            ILazlosIngredients(ingredientsContractAddress).decreaseIngredientSupply(tokenId, 1);

            unchecked {
                expectedPrice += ingredient.price;
            }
        }

        return _bakePizza(tokenIds, false);
    }

    function verifySignature(bytes32 messageHash, bytes32 r, bytes32 s, uint8 v) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes memory prefixedMessage = abi.encodePacked(prefix, messageHash);
        bytes32 hashedMessage = keccak256(prefixedMessage);
        return ecrecover(hashedMessage, v, r, s);
    }

    function artistWithdraw() public nonReentrant {
        uint256 amountToBePayed = artistAllowedWithdrawalAmount(msg.sender);
        artistWithdrawalAmount[msg.sender] += amountToBePayed;

        (bool success,) = msg.sender.call{value : amountToBePayed}('');
        require(success, "Withdrawal failed.");
    }

    function artistAllowedWithdrawalAmount(address artist) public view returns( uint256) {
        uint256 earnedCommission = artistTotalCommission(artist);
        uint256 amountWithdrawn = artistWithdrawalAmount[artist];

        require(earnedCommission > amountWithdrawn, "Hasn't earned any more commission.");
        uint256 withdrawalAmount = earnedCommission - amountWithdrawn;
        return withdrawalAmount;
    }

    function artistTotalCommission(address artist) public view returns (uint256) {
        uint256 numIngredients = ILazlosIngredients(ingredientsContractAddress).getNumIngredients();

        uint256 artistCommission;
        for (uint256 tokenId = 1; tokenId <= numIngredients; tokenId++) {
            Ingredient memory ingredient = ILazlosIngredients(ingredientsContractAddress).getIngredient(tokenId);

            if (ingredient.artist != artist) {
                continue;
            }

            uint256 numSold = ingredient.initialSupply - ingredient.supply;
            uint256 ingredientRevenue = numSold * ingredient.price;
            uint256 artistsIngredientCommission = ingredientRevenue / 10;
            artistCommission += artistsIngredientCommission;
        }

        return artistCommission;
    }

    struct Payout {
        uint256 payoutBlock;
        uint256 amount;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    function redeemPayout(Payout[] memory payouts) public nonReentrant {
        uint256 totalPayout;
        for (uint256 i; i < payouts.length; i++) {
            Payout memory payout = payouts[i];

            bytes32 messageHash = keccak256(abi.encodePacked(
                payout.payoutBlock,
                msg.sender,
                payout.amount
            ));
            address signerAddress = verifySignature(messageHash, payout.r, payout.s, payout.v);
            bool validSignature = signerAddress == systemAddress;
            require(validSignature, 'Invalid signature.');

            require(!isPaidByBlockAndAddress[payout.payoutBlock][msg.sender], 'Address already been paid for this block.');

            isPaidByBlockAndAddress[payout.payoutBlock][msg.sender] = true;
            totalPayout += payout.amount;
        }

        if (totalPayout > 0) {
            (bool success,) = msg.sender.call{value : totalPayout}('');
            require(success, "Withdrawal failed.");
        }
    }

    function isPaidOutForBlock(address addr, uint256 payoutBlock) public view returns (bool) {
        return isPaidByBlockAndAddress[payoutBlock][addr];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

enum IngredientType {
    Base,
    Sauce,
    Cheese,
    Meat,
    Topping
}

struct Ingredient {
    string name;
    IngredientType ingredientType;
    address artist;
    uint256 price;
    uint256 supply;
    uint256 initialSupply;
}

struct Pizza {
    uint16 base;
    uint16 sauce;
    uint16[3] cheeses;
    uint16[4] meats;
    uint16[4] toppings;
}

interface ILazlosIngredients {
    function getNumIngredients() external view returns (uint256);
    function getIngredient(uint256 tokenId) external view returns (Ingredient memory);
    function increaseIngredientSupply(uint256 tokenId, uint256 amount) external;
    function decreaseIngredientSupply(uint256 tokenId, uint256 amount) external;
    function mintIngredients(address addr, uint256[] memory tokenIds, uint256[] memory amounts) external;
    function burnIngredients(address addr, uint256[] memory tokenIds, uint256[] memory amounts) external;
    function balanceOfAddress(address addr, uint256 tokenId) external view returns (uint256);
}

interface ILazlosPizzas {
    function bake(address baker, Pizza memory pizza) external returns (uint256);
    function rebake(address baker, uint256 pizzaTokenId, Pizza memory pizza) external;
    function pizza(uint256 tokenId) external view returns (Pizza memory);
    function burn(uint256 tokenId) external;
}

interface ILazlosRendering {
    function ingredientTokenMetadata(uint256 id) external view returns (string memory); 
    function pizzaTokenMetadata(uint256 id) external view returns (string memory); 
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