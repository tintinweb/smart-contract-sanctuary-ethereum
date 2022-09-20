//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "./interfaces/IERC20Burnable.sol";
import "./interfaces/IERC1155Burnable.sol";
import "./PokemonStorage.sol";

/**
 * @title Pokemons contract.
 * NOTE: The contract allows to mint any pokemon, as well as evolve them following the rules
 * from the official game outside the blockchain.
 */
contract Pokemons is PokemonStorage {
    uint256 private _mintFee;
    uint256 private _evolveLevelFee;
    uint256 private _totalSupply;
    uint256 private _maxSupply;
    IERC20Burnable private _level;
    IERC1155Burnable private _stones;

    /**
     * @dev Emitted when the owner withdraw ether from the contract.
     * @param owner owner address.
     * @param amount amount of ether.
     */
    event WithdrawalOfOwner(address owner, uint256 indexed amount);

    /**
     * @dev Emitted when the owner of the contract call setMaxSupply().
     * @param newMaxSupply new _maxSupply.
     */
    event MaxSupplyUpdated(uint256 newMaxSupply);

    /**
     * @dev Emitted when the owner of the contract call setMintFee().
     * @param newFeePrice new fee for minting pokemons.
     */
    event MintFeeUpdated(uint256 newFeePrice);

    /**
     * @dev Emitted when the owner of the contract call setEvolveLevelFee().
     * @param evolveFeeUpdated new fee for evolving pokemons.
     */
    event EvolveFeeUpdated(uint256 evolveFeeUpdated);

    /**
     * @dev Emitted when the owner of the contract call setNewLevelContract().
     * @param level new `Level` instance.
     */
    event NewLevelContract(IERC20Burnable level);

    /**
     * @dev Emitted when the owner of the contract call setNewStonesContract().
     * @param stones new `Stones` instance.
     */
    event NewStonesContract(IERC1155Burnable stones);

    /**
     * @dev Emitted when new token minted.
     * @param tokenId token Id.
     * @param mintTime block.timestamp of mint.
     * @param owner address of the owner of the token.
     */
    event NewPokemon(uint256 indexed tokenId, uint256 mintTime, address owner);

    /**
     * @dev Emitted when evolveWithLevel() occured.
     * @param tokenId token Id.
     * @param newTokenId token Id of new Token.
     * @param evolutionTime block.timestamp of evolution.
     * @param owner address of the owner of the token.
     */
    event EvolvedWithLevel(uint256 indexed tokenId, uint256 indexed newTokenId, uint256 evolutionTime, address owner);

    /**
     * @dev Emitted when evolveWithStone() occured.
     * @param tokenId token Id.
     * @param newTokenId token Id of new Token.
     * @param stoneId Id of the stone erc-1155 token that was used to evolve the pokemon.
     * @param evolutionTime block.timestamp of evolution.
     * @param owner address of the owner of the token.
     */
    event EvolvedWithStone(
        uint256 indexed tokenId,
        uint256 indexed newTokenId,
        uint256 stoneId,
        uint256 evolutionTime,
        address owner
    );

    /**
     * @dev Sets up the mint fee, the Evolve fee, and both IERC20Burnable IERC1155Burnable instances.
     * @param mintFee_ initial mint price for mintPokemon().
     * @param evolveLevelFee_ initial fee for Evolves in Level tokens.
     * @param maxSupply_ initial max Supply for tokens.
     * @param level_ address of Level erc-20 standard contract.
     * @param stones_ address of Stones erc-1155 standard contract.
     */
    constructor(
        uint256 mintFee_,
        uint256 evolveLevelFee_,
        uint256 maxSupply_,
        address level_,
        address stones_
    ) {
        require(mintFee_ > 0, "Mint Fee cannot be 0");
        require(evolveLevelFee_ > 0, "Evolve Level Fee cannot be 0");
        require(maxSupply_ > 0, "Max supply cannot be zero");
        require(level_ != address(0), "ERC-20 cannot be zero address");
        require(stones_ != address(0), "ERC-1155 cannot be zero address");
        _mintFee = mintFee_;
        _evolveLevelFee = evolveLevelFee_;
        _maxSupply = maxSupply_;
        _level = IERC20Burnable(level_);
        _stones = IERC1155Burnable(stones_);
    }

    /**
     * @dev This is a function to mint Pokémon tokens dependig on pseudo randomness.
     * One of 905 different Pokémon is pseudo - randomly selected and minted to the user.
     * The mint costs ether and the price of the mint is set by the owner.
     *
     * Requirements:
     *
     * - `msg.value` must be higher or equal to `_mintFee`.
     * - Users can mint tokens until the `_maxSupply` value is reached.
     *
     * Emits a {NewPokemon} event.
     */
    function mintPokemon() external payable {
        require(_totalSupply <= _maxSupply, "Collection reached max supply");
        require(msg.value >= _mintFee, "Mint fee required");
        uint256 pseudoRandom = (uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) %
            905) + 1;
        _totalSupply++;
        _mint(msg.sender, pseudoRandom, 1, "");
        emit NewPokemon(pseudoRandom, block.timestamp, msg.sender);
    }

    /**
     * @dev This is a function for Pokémon evolution. Contract has data about every
     * real Level type and Stone type evolutions.
     *
     * Requirements:
     *
     * - Users can evolve Pokemons until the `_maxSupply` value is reached.
     * - The caller must be the owner of the token specified as a parameter.
     * - If such an evolution option exists, the user must buy level/stone tokens depending on the type of evolution.
     * - The user must buy and approve one `stone` type token for this contract if the evolutionWithStone() occured.
     * - The user must buy and approve `_evolveLevelFee` amount of `level` tokens for this contract if
     * the evolveWithLevel() occured.
     *
     * @param pokemonNumber_ pokemon id to be evolved.
     *
     * Emits a {EvolvedWithStone} or {EvolvedWithLevel} event.
     */
    function evolvePokemon(uint256 pokemonNumber_) external {
        require(_totalSupply <= _maxSupply, "Collection reached max supply");
        require(balanceOf(msg.sender, pokemonNumber_) > 0, "Caller not the owner");
        (uint256 whichMethodOfEvolve, uint256 newPokemonId) = checkAvailableEvolve(pokemonNumber_);
        if (whichMethodOfEvolve < 14) {
            evolveWithStone(pokemonNumber_, newPokemonId, whichMethodOfEvolve);
        } else if (whichMethodOfEvolve == 14) {
            evolveWithLevel(pokemonNumber_);
        } else revert("Token cannot be updated");
    }

    /**
     * @dev This is a function for Pokémon evolution with erc-1155 standart `stone` token.
     * Each Pokémon is unique and various evolution options are stored in the "PokemonStorage" contract.
     * Using this method, the user pays with erc-1155 `stone` tokens, which are eventually burned.
     * See {PokemonStorage - isThunderEvolveAvailable(), isMoonEvolveAvailable()...}.
     *
     * Requirements:
     *
     * - Users can evolve Pokemons until the `_maxSupply` value is reached.
     * - Users required to buy specific `stone`. User can check which `stone` is required calling checkAvailableEvolve().
     * - Users required to approve one specific `stone` for this contract in order to pay for the evolution.
     *
     * @param pokemonNumber_ pokemon id to be evolved.
     * @param newPokemonId_ id of new pokemon to be minted.
     * @param whichStoneToUse_ required stone to evolve `pokemonNumber_`.
     *
     * Emits a {EvolvedWithStone} event.
     */
    function evolveWithStone(
        uint256 pokemonNumber_,
        uint256 newPokemonId_,
        uint256 whichStoneToUse_
    ) private {
        _stones.burn(msg.sender, whichStoneToUse_, 1);
        _mint(msg.sender, newPokemonId_, 1, "");
        _totalSupply++;
        emit EvolvedWithStone(pokemonNumber_, newPokemonId_, whichStoneToUse_, block.timestamp, msg.sender);
    }

    /**
     * @dev This is a function for Pokémon evolution with erc-20 standart `_maxSupply` token.
     * Each Pokémon is unique and various evolution options are stored in the "PokemonStorage" contract.
     * Using this method, the user pays with erc-20 `level` tokens, which are eventually burned.
     * See {PokemonStorage - isEvolveNotAvailable()}.
     *
     * Requirements:
     *
     * - Users can evolve Pokemons until the `_maxSupply` value is reached.
     * - Users required to buy `level` tokens of `_evolveLevelFee` amount.
     * - Users required to approve `level` tokens of `_evolveLevelFee` amount for this contract
     *
     * @param pokemonNumber_ pokemon id to be evolved.
     *
     * Emits a {EvolvedWithLevel} event.
     */
    function evolveWithLevel(uint256 pokemonNumber_) private {
        _level.burnFrom(msg.sender, _evolveLevelFee);
        uint256 newPokemonId = pokemonNumber_ + 1;
        _mint(msg.sender, newPokemonId, 1, "");
        _totalSupply++;
        emit EvolvedWithLevel(pokemonNumber_, newPokemonId, block.timestamp, msg.sender);
    }

    /**
     * @dev This is a function to check if evolution is available, and if so, which one.
     * Function return Id of stone or data saying that `level` evolution is available or data saying
     * that this Pokémon cannot be evolved.
     * @param pokemonNumber_ pokemon Id to get evolution data.
     */
    function checkAvailableEvolve(uint256 pokemonNumber_) public view returns (uint256, uint256) {
        if (true == isEvolveNotAvailable(pokemonNumber_)) {
            return (15, 0);
        } else if (isThunderEvolveAvailable(pokemonNumber_) != 0) {
            return (0, isThunderEvolveAvailable(pokemonNumber_));
        } else if (isMoonEvolveAvailable(pokemonNumber_) != 0) {
            return (1, isMoonEvolveAvailable(pokemonNumber_));
        } else if (isFireEvolveAvailable(pokemonNumber_) != 0) {
            return (2, isFireEvolveAvailable(pokemonNumber_));
        } else if (isLeafEvolveAvailable(pokemonNumber_) != 0) {
            return (3, isLeafEvolveAvailable(pokemonNumber_));
        } else if (isSunEvolveAvailable(pokemonNumber_) != 0) {
            return (4, isSunEvolveAvailable(pokemonNumber_));
        } else if (isWaterEvolveAvailable(pokemonNumber_) != 0) {
            return (5, isWaterEvolveAvailable(pokemonNumber_));
        } else if (isBlackAuguriteEvolveAvailable(pokemonNumber_) != 0) {
            return (6, isBlackAuguriteEvolveAvailable(pokemonNumber_));
        } else if (isShinyEvolveAvailable(pokemonNumber_) != 0) {
            return (7, isShinyEvolveAvailable(pokemonNumber_));
        } else if (isDuskEvolveAvailable(pokemonNumber_) != 0) {
            return (8, isDuskEvolveAvailable(pokemonNumber_));
        } else if (isRazorClawEvolveAvailable(pokemonNumber_) != 0) {
            return (9, isRazorClawEvolveAvailable(pokemonNumber_));
        } else if (isPeatBlockEvolveAvailable(pokemonNumber_) != 0) {
            return (10, isPeatBlockEvolveAvailable(pokemonNumber_));
        } else if (isTartAppleEvolveAvailable(pokemonNumber_) != 0) {
            return (11, isTartAppleEvolveAvailable(pokemonNumber_));
        } else if (isCrackedPotEvolveAvailable(pokemonNumber_) != 0) {
            return (12, isCrackedPotEvolveAvailable(pokemonNumber_));
        } else if (isOvalEvolveAvailable(pokemonNumber_) != 0) {
            return (13, isOvalEvolveAvailable(pokemonNumber_));
        } else return (14, 16);
    }

    /**
     * @dev Owner can withdraw Ether from contract.
     *
     * Emits a {WithdrawalOfOwner} event.
     */
    function withdrawETH(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Not enough ETH");
        payable(owner()).transfer(amount);
        emit WithdrawalOfOwner(msg.sender, amount);
    }

    /**
     * @dev Set new `_maxSupply`. New max Supply required to be equal or higher
     * than _totalSupply. Can only be called by the owner of the contract.
     * @param maxSupply_ new max Supply of tokens.
     *
     * Emits a {MaxSupplyUpdated} event.
     */
    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        require(maxSupply_ > 0, "Max supply cannot be zero");
        require(maxSupply_ >= _totalSupply, "Max supply cannot be lower than total supply");
        _maxSupply = maxSupply_;
        emit MaxSupplyUpdated(_maxSupply);
    }

    /**
     * @dev Set new `_mintFee`. Function can only be called by the owner of the contract.
     * Users are required to pay this fee whenever they want call mintPokemon() function.
     * Function can only be called by the owner of the contract.
     * @param newMintFee_ new mint pokemon fee.
     *
     * Emits a {MintFeeUpdated} event.
     */
    function setMintFee(uint256 newMintFee_) external onlyOwner {
        require(newMintFee_ > 0, "Mint Fee cannot be zero");
        _mintFee = newMintFee_;
        emit MintFeeUpdated(_mintFee);
    }

    /**
     * @dev Set new `_evolveLevelFee`. Function can only be called by the owner of the contract.
     * Users are required to pay this fee whenever they want call evolvePokemon() function.
     * @param evolveLevelFee_ new evolve pokemon fee.
     *
     * Emits a {EvolveFeeUpdated} event.
     */
    function setEvolveLevelFee(uint256 evolveLevelFee_) external onlyOwner {
        require(evolveLevelFee_ > 0, "Evolve Fee cannot be zero");
        _evolveLevelFee = evolveLevelFee_;
        emit EvolveFeeUpdated(_evolveLevelFee);
    }

    /**
     * @dev Set new `_level` contract instance. Can only be called by the owner of the contract.
     * New `_level` contract instance required not to be address(0)
     * @param level_ new `Level` instance.
     *
     * Emits a {NewLevelContract} event.
     */
    function setNewLevelContract(address level_) external onlyOwner {
        require(level_ != address(0), "Level cannot be zero address");
        _level = IERC20Burnable(level_);
        emit NewLevelContract(_level);
    }

    /**
     * @dev Set new `_stones` contract instance. Can only be called by the owner of the contract.
     * New `_stones` contract instance required not to be address(0)
     * @param stones_ new `Stones` instance.
     *
     * Emits a {NewStonesContract} event.
     */
    function setNewStonesContract(address stones_) external onlyOwner {
        require(stones_ != address(0), "Stones cannot be zero address");
        _stones = IERC1155Burnable(stones_);
        emit NewStonesContract(_stones);
    }

    /**
     * @dev Returns max supply.
     */
    function getMaxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev Returns the Pokemon mint fee.
     */
    function getMintFee() external view returns (uint256) {
        return _mintFee;
    }

    /**
     * @dev Returns the Evolve fee in `level` tokens.
     */
    function getEvolveLevelFee() external view returns (uint256) {
        return _evolveLevelFee;
    }

    /**
     * @dev Returns address of the Level contract.
     */
    function getLevelAddress() external view returns (IERC20Burnable) {
        return _level;
    }

    /**
     * @dev Returns address of the Stones contract.
     */
    function getStonesAddress() external view returns (IERC1155Burnable) {
        return _stones;
    }

    /**
     * @dev Returns the actual total supply so far.
     */
    function getTotalSupply() public view returns (uint256) {
        return _totalSupply;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the ERC20Burnable extension.
 */
interface IERC20Burnable is IERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @dev Interface of the ERC1155Burnable extension.
 */
interface IERC1155Burnable is IERC1155 {
    /**
     * @dev Destroys `value` amount of `id` tokens from the `account`.
     *
     * See {ERC1155-_burn}.
     */
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

/**
 * @title PokemonStorage contract.
 * NOTE: The contract contains all possible evolution data.
 * @dev Contract use Bitmaps from openzeppelin to save on Gas
 */
contract PokemonStorage is ERC1155, Ownable {
    using BitMaps for BitMaps.BitMap;
    BitMaps.BitMap private _latestInEvolution;
    mapping(uint256 => uint256) private _thunderEvolutions;
    mapping(uint256 => uint256) private _moonEvolutions;
    mapping(uint256 => uint256) private _fireEvolutions;
    mapping(uint256 => uint256) private _leafEvolutions;
    mapping(uint256 => uint256) private _sunEvolutions;
    mapping(uint256 => uint256) private _waterEvolutions;
    mapping(uint256 => uint256) private _blackAuguriteEvolutions;
    mapping(uint256 => uint256) private _shinyEvolutions;
    mapping(uint256 => uint256) private _duskEvolutions;
    mapping(uint256 => uint256) private _razorClawEvolutions;
    mapping(uint256 => uint256) private _peatBlockEvolutions;
    mapping(uint256 => uint256) private _tartAppleEvolutions;
    mapping(uint256 => uint256) private _crackedPotEvolutions;
    mapping(uint256 => uint256) private _ovalEvolutions;

    /**
     * @dev Returns bool about availability of evolution.
     */
    function isEvolveNotAvailable(uint256 pokemonNumber) public view returns (bool) {
        return _latestInEvolution.get(pokemonNumber);
    }

    /**
     * @dev Returns data about the possibility of evolution with a thunder stone.
     */
    function isThunderEvolveAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _thunderEvolutions[pokemonNumber];
    }

    /**
     * @dev Returns data about the possibility of evolution with a moon stone.
     */
    function isMoonEvolveAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _moonEvolutions[pokemonNumber];
    }

    /**
     * @dev Returns data about the possibility of evolution with a fire stone.
     */
    function isFireEvolveAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _fireEvolutions[pokemonNumber];
    }

    /**
     * @dev Returns data about the possibility of evolution with a leaf stone.
     */
    function isLeafEvolveAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _leafEvolutions[pokemonNumber];
    }

    /**
     * @dev Returns data about the possibility of evolution with a sun stone.
     */
    function isSunEvolveAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _sunEvolutions[pokemonNumber];
    }

    /**
     * @dev Returns data about the possibility of evolution with a water stone.
     */
    function isWaterEvolveAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _waterEvolutions[pokemonNumber];
    }

    /**
     * @dev Returns data about the possibility of evolution with a black augurite.
     */
    function isBlackAuguriteEvolveAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _blackAuguriteEvolutions[pokemonNumber];
    }

    /**
     * @dev Returns data about the possibility of evolution with a shiny stone.
     */
    function isShinyEvolveAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _shinyEvolutions[pokemonNumber];
    }

    /**
     * @dev Returns data about the possibility of evolution with a dusk stone.
     */
    function isDuskEvolveAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _duskEvolutions[pokemonNumber];
    }

    /**
     * @dev Returns data about the possibility of evolution with a razor claw.
     */
    function isRazorClawEvolveAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _razorClawEvolutions[pokemonNumber];
    }

    /**
     * @dev Returns data about the possibility of evolution with a peat block.
     */
    function isPeatBlockEvolveAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _peatBlockEvolutions[pokemonNumber];
    }

    /**
     * @dev Returns data about the possibility of evolution with a tart apple.
     */
    function isTartAppleEvolveAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _tartAppleEvolutions[pokemonNumber];
    }

    /**
     * @dev Returns data about the possibility of evolution with a cracked pot.
     */
    function isCrackedPotEvolveAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _crackedPotEvolutions[pokemonNumber];
    }

    /**
     * @dev Returns data about the possibility of evolution with a oval stone
     */
    function isOvalEvolveAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _ovalEvolutions[pokemonNumber];
    }

    /**
     * @dev Returns uri of each token.
     */
    function uri(uint256 tokenId) public pure override returns (string memory) {
        return (
            string(
                abi.encodePacked(
                    "ipfs://bafybeidhzhc5wjpdvqjldvl5pkbq4lxf2udwkltfx5qzo6gn327xpidpue/",
                    Strings.toString(tokenId)
                )
            )
        );
    }

    /**
     * @dev Stores data on all `stone` type evolving opportunities and all latest Pokémons in
     * the chain of evolution.
     */
    constructor() ERC1155("ipfs://bafybeidhzhc5wjpdvqjldvl5pkbq4lxf2udwkltfx5qzo6gn327xpidpue/") {
        _latestInEvolution.set(3);
        _latestInEvolution.set(6);
        _latestInEvolution.set(9);
        _latestInEvolution.set(12);
        _latestInEvolution.set(15);
        _latestInEvolution.set(18);
        _latestInEvolution.set(20);
        _latestInEvolution.set(22);
        _latestInEvolution.set(24);
        _latestInEvolution.set(26);
        _latestInEvolution.set(28);
        _latestInEvolution.set(31);
        _latestInEvolution.set(34);
        _latestInEvolution.set(36);
        _latestInEvolution.set(38);
        _latestInEvolution.set(40);
        _latestInEvolution.set(42);
        _latestInEvolution.set(45);
        _latestInEvolution.set(47);
        _latestInEvolution.set(49);
        _latestInEvolution.set(51);
        _latestInEvolution.set(53);
        _latestInEvolution.set(55);
        _latestInEvolution.set(57);
        _latestInEvolution.set(59);
        _latestInEvolution.set(62);
        _latestInEvolution.set(65);
        _latestInEvolution.set(68);
        _latestInEvolution.set(71);
        _latestInEvolution.set(73);
        _latestInEvolution.set(76);
        _latestInEvolution.set(78);
        _latestInEvolution.set(80);
        _latestInEvolution.set(82);
        _latestInEvolution.set(83);
        _latestInEvolution.set(85);
        _latestInEvolution.set(87);
        _latestInEvolution.set(89);
        _latestInEvolution.set(91);
        _latestInEvolution.set(94);
        _latestInEvolution.set(95);
        _latestInEvolution.set(97);
        _latestInEvolution.set(99);

        _latestInEvolution.set(101);
        _latestInEvolution.set(103);
        _latestInEvolution.set(105);
        _latestInEvolution.set(106);
        _latestInEvolution.set(107);
        _latestInEvolution.set(101);
        _latestInEvolution.set(103);
        _latestInEvolution.set(105);
        _latestInEvolution.set(106);
        _latestInEvolution.set(107);
        _latestInEvolution.set(108);
        _latestInEvolution.set(110);
        _latestInEvolution.set(112);
        _latestInEvolution.set(113);
        _latestInEvolution.set(114);
        _latestInEvolution.set(117);
        _latestInEvolution.set(119);
        _latestInEvolution.set(121);
        _latestInEvolution.set(122);
        _latestInEvolution.set(124);
        _latestInEvolution.set(125);
        _latestInEvolution.set(126);
        _latestInEvolution.set(127);
        _latestInEvolution.set(128);
        _latestInEvolution.set(130);
        _latestInEvolution.set(131);
        _latestInEvolution.set(132);
        _latestInEvolution.set(134);
        _latestInEvolution.set(135);
        _latestInEvolution.set(136);
        _latestInEvolution.set(137);
        _latestInEvolution.set(139);
        _latestInEvolution.set(141);
        _latestInEvolution.set(142);
        _latestInEvolution.set(143);
        _latestInEvolution.set(145);
        _latestInEvolution.set(146);
        _latestInEvolution.set(149);
        _latestInEvolution.set(150);
        _latestInEvolution.set(151);
        _latestInEvolution.set(154);
        _latestInEvolution.set(157);
        _latestInEvolution.set(160);
        _latestInEvolution.set(162);
        _latestInEvolution.set(164);
        _latestInEvolution.set(166);
        _latestInEvolution.set(168);
        _latestInEvolution.set(169);
        _latestInEvolution.set(171);
        _latestInEvolution.set(172);
        _latestInEvolution.set(173);
        _latestInEvolution.set(174);
        _latestInEvolution.set(178);
        _latestInEvolution.set(181);
        _latestInEvolution.set(182);
        _latestInEvolution.set(184);
        _latestInEvolution.set(185);
        _latestInEvolution.set(186);
        _latestInEvolution.set(189);
        _latestInEvolution.set(190);
        _latestInEvolution.set(192);
        _latestInEvolution.set(193);
        _latestInEvolution.set(195);
        _latestInEvolution.set(196);
        _latestInEvolution.set(197);
        _latestInEvolution.set(199);

        _latestInEvolution.set(201);
        _latestInEvolution.set(202);
        _latestInEvolution.set(203);
        _latestInEvolution.set(205);
        _latestInEvolution.set(206);
        _latestInEvolution.set(207);
        _latestInEvolution.set(208);
        _latestInEvolution.set(210);
        _latestInEvolution.set(211);
        _latestInEvolution.set(212);
        _latestInEvolution.set(213);
        _latestInEvolution.set(214);
        _latestInEvolution.set(219);
        _latestInEvolution.set(221);
        _latestInEvolution.set(222);
        _latestInEvolution.set(224);
        _latestInEvolution.set(225);
        _latestInEvolution.set(226);
        _latestInEvolution.set(227);
        _latestInEvolution.set(229);
        _latestInEvolution.set(230);
        _latestInEvolution.set(232);
        _latestInEvolution.set(233);
        _latestInEvolution.set(234);
        _latestInEvolution.set(235);
        _latestInEvolution.set(236);
        _latestInEvolution.set(237);
        _latestInEvolution.set(238);
        _latestInEvolution.set(239);
        _latestInEvolution.set(240);
        _latestInEvolution.set(241);
        _latestInEvolution.set(242);
        _latestInEvolution.set(243);
        _latestInEvolution.set(244);
        _latestInEvolution.set(245);
        _latestInEvolution.set(248);
        _latestInEvolution.set(249);
        _latestInEvolution.set(250);
        _latestInEvolution.set(251);
        _latestInEvolution.set(254);
        _latestInEvolution.set(257);
        _latestInEvolution.set(260);
        _latestInEvolution.set(262);
        _latestInEvolution.set(264);
        _latestInEvolution.set(269);
        _latestInEvolution.set(272);
        _latestInEvolution.set(275);
        _latestInEvolution.set(277);
        _latestInEvolution.set(279);
        _latestInEvolution.set(282);
        _latestInEvolution.set(284);
        _latestInEvolution.set(286);
        _latestInEvolution.set(289);
        _latestInEvolution.set(292);
        _latestInEvolution.set(295);
        _latestInEvolution.set(297);
        _latestInEvolution.set(298);
        _latestInEvolution.set(299);

        _latestInEvolution.set(301);
        _latestInEvolution.set(302);
        _latestInEvolution.set(303);
        _latestInEvolution.set(306);
        _latestInEvolution.set(308);
        _latestInEvolution.set(310);
        _latestInEvolution.set(311);
        _latestInEvolution.set(312);
        _latestInEvolution.set(313);
        _latestInEvolution.set(314);
        _latestInEvolution.set(317);
        _latestInEvolution.set(319);
        _latestInEvolution.set(321);
        _latestInEvolution.set(323);
        _latestInEvolution.set(324);
        _latestInEvolution.set(326);
        _latestInEvolution.set(327);
        _latestInEvolution.set(330);
        _latestInEvolution.set(332);
        _latestInEvolution.set(334);
        _latestInEvolution.set(335);
        _latestInEvolution.set(336);
        _latestInEvolution.set(337);
        _latestInEvolution.set(338);
        _latestInEvolution.set(340);
        _latestInEvolution.set(342);
        _latestInEvolution.set(344);
        _latestInEvolution.set(346);
        _latestInEvolution.set(348);
        _latestInEvolution.set(350);
        _latestInEvolution.set(351);
        _latestInEvolution.set(352);
        _latestInEvolution.set(354);
        _latestInEvolution.set(356);
        _latestInEvolution.set(357);
        _latestInEvolution.set(358);
        _latestInEvolution.set(359);
        _latestInEvolution.set(360);
        _latestInEvolution.set(362);
        _latestInEvolution.set(365);
        _latestInEvolution.set(368);
        _latestInEvolution.set(369);
        _latestInEvolution.set(370);
        _latestInEvolution.set(373);
        _latestInEvolution.set(376);
        _latestInEvolution.set(377);
        _latestInEvolution.set(378);
        _latestInEvolution.set(379);
        _latestInEvolution.set(380);
        _latestInEvolution.set(381);
        _latestInEvolution.set(382);
        _latestInEvolution.set(383);
        _latestInEvolution.set(384);
        _latestInEvolution.set(385);
        _latestInEvolution.set(386);
        _latestInEvolution.set(389);
        _latestInEvolution.set(392);
        _latestInEvolution.set(395);
        _latestInEvolution.set(398);

        _latestInEvolution.set(400);
        _latestInEvolution.set(402);
        _latestInEvolution.set(407);
        _latestInEvolution.set(405);
        _latestInEvolution.set(409);
        _latestInEvolution.set(411);
        _latestInEvolution.set(414);
        _latestInEvolution.set(416);
        _latestInEvolution.set(419);
        _latestInEvolution.set(421);
        _latestInEvolution.set(423);
        _latestInEvolution.set(424);
        _latestInEvolution.set(426);
        _latestInEvolution.set(428);
        _latestInEvolution.set(429);
        _latestInEvolution.set(430);
        _latestInEvolution.set(432);
        _latestInEvolution.set(433);
        _latestInEvolution.set(435);
        _latestInEvolution.set(437);
        _latestInEvolution.set(438);
        _latestInEvolution.set(439);
        _latestInEvolution.set(441);
        _latestInEvolution.set(442);
        _latestInEvolution.set(445);
        _latestInEvolution.set(446);
        _latestInEvolution.set(448);
        _latestInEvolution.set(450);
        _latestInEvolution.set(452);
        _latestInEvolution.set(454);
        _latestInEvolution.set(455);
        _latestInEvolution.set(457);
        _latestInEvolution.set(458);
        _latestInEvolution.set(460);
        _latestInEvolution.set(461);
        _latestInEvolution.set(462);
        _latestInEvolution.set(463);
        _latestInEvolution.set(464);
        _latestInEvolution.set(465);
        _latestInEvolution.set(466);
        _latestInEvolution.set(467);
        _latestInEvolution.set(468);
        _latestInEvolution.set(469);
        _latestInEvolution.set(470);
        _latestInEvolution.set(471);
        _latestInEvolution.set(472);
        _latestInEvolution.set(473);
        _latestInEvolution.set(474);
        _latestInEvolution.set(475);
        _latestInEvolution.set(476);
        _latestInEvolution.set(477);
        _latestInEvolution.set(478);
        _latestInEvolution.set(479);
        _latestInEvolution.set(480);
        _latestInEvolution.set(481);
        _latestInEvolution.set(482);
        _latestInEvolution.set(483);
        _latestInEvolution.set(484);
        _latestInEvolution.set(485);
        _latestInEvolution.set(486);
        _latestInEvolution.set(487);
        _latestInEvolution.set(488);
        _latestInEvolution.set(489);
        _latestInEvolution.set(490);
        _latestInEvolution.set(491);
        _latestInEvolution.set(492);
        _latestInEvolution.set(493);
        _latestInEvolution.set(494);
        _latestInEvolution.set(497);

        _latestInEvolution.set(500);
        _latestInEvolution.set(503);
        _latestInEvolution.set(505);
        _latestInEvolution.set(508);
        _latestInEvolution.set(510);
        _latestInEvolution.set(512);
        _latestInEvolution.set(514);
        _latestInEvolution.set(516);
        _latestInEvolution.set(518);
        _latestInEvolution.set(521);
        _latestInEvolution.set(523);
        _latestInEvolution.set(526);
        _latestInEvolution.set(528);
        _latestInEvolution.set(530);
        _latestInEvolution.set(531);
        _latestInEvolution.set(534);
        _latestInEvolution.set(537);
        _latestInEvolution.set(538);
        _latestInEvolution.set(539);
        _latestInEvolution.set(542);
        _latestInEvolution.set(545);
        _latestInEvolution.set(547);
        _latestInEvolution.set(549);
        _latestInEvolution.set(550);
        _latestInEvolution.set(553);
        _latestInEvolution.set(555);
        _latestInEvolution.set(556);
        _latestInEvolution.set(558);
        _latestInEvolution.set(560);
        _latestInEvolution.set(561);
        _latestInEvolution.set(563);
        _latestInEvolution.set(565);
        _latestInEvolution.set(567);
        _latestInEvolution.set(569);
        _latestInEvolution.set(571);
        _latestInEvolution.set(573);
        _latestInEvolution.set(576);
        _latestInEvolution.set(579);
        _latestInEvolution.set(581);
        _latestInEvolution.set(584);
        _latestInEvolution.set(586);
        _latestInEvolution.set(587);
        _latestInEvolution.set(589);
        _latestInEvolution.set(591);
        _latestInEvolution.set(593);
        _latestInEvolution.set(594);
        _latestInEvolution.set(596);
        _latestInEvolution.set(598);

        _latestInEvolution.set(601);
        _latestInEvolution.set(604);
        _latestInEvolution.set(606);
        _latestInEvolution.set(609);
        _latestInEvolution.set(612);
        _latestInEvolution.set(614);
        _latestInEvolution.set(615);
        _latestInEvolution.set(617);
        _latestInEvolution.set(618);
        _latestInEvolution.set(620);
        _latestInEvolution.set(621);
        _latestInEvolution.set(623);
        _latestInEvolution.set(625);
        _latestInEvolution.set(626);
        _latestInEvolution.set(628);
        _latestInEvolution.set(630);
        _latestInEvolution.set(631);
        _latestInEvolution.set(632);
        _latestInEvolution.set(635);
        _latestInEvolution.set(637);
        _latestInEvolution.set(638);
        _latestInEvolution.set(639);
        _latestInEvolution.set(640);
        _latestInEvolution.set(641);
        _latestInEvolution.set(642);
        _latestInEvolution.set(643);
        _latestInEvolution.set(644);
        _latestInEvolution.set(645);
        _latestInEvolution.set(646);
        _latestInEvolution.set(647);
        _latestInEvolution.set(648);
        _latestInEvolution.set(649);
        _latestInEvolution.set(652);
        _latestInEvolution.set(655);
        _latestInEvolution.set(658);
        _latestInEvolution.set(660);
        _latestInEvolution.set(663);
        _latestInEvolution.set(666);
        _latestInEvolution.set(668);
        _latestInEvolution.set(671);
        _latestInEvolution.set(673);
        _latestInEvolution.set(675);
        _latestInEvolution.set(676);
        _latestInEvolution.set(678);
        _latestInEvolution.set(681);
        _latestInEvolution.set(683);
        _latestInEvolution.set(685);
        _latestInEvolution.set(687);
        _latestInEvolution.set(689);
        _latestInEvolution.set(691);
        _latestInEvolution.set(693);
        _latestInEvolution.set(695);
        _latestInEvolution.set(697);
        _latestInEvolution.set(699);

        _latestInEvolution.set(700);
        _latestInEvolution.set(701);
        _latestInEvolution.set(702);
        _latestInEvolution.set(703);
        _latestInEvolution.set(706);
        _latestInEvolution.set(707);
        _latestInEvolution.set(709);
        _latestInEvolution.set(711);
        _latestInEvolution.set(713);
        _latestInEvolution.set(715);
        _latestInEvolution.set(716);
        _latestInEvolution.set(717);
        _latestInEvolution.set(718);
        _latestInEvolution.set(719);
        _latestInEvolution.set(720);
        _latestInEvolution.set(721);
        _latestInEvolution.set(724);
        _latestInEvolution.set(727);
        _latestInEvolution.set(730);
        _latestInEvolution.set(733);
        _latestInEvolution.set(735);
        _latestInEvolution.set(738);
        _latestInEvolution.set(740);
        _latestInEvolution.set(743);
        _latestInEvolution.set(745);
        _latestInEvolution.set(746);
        _latestInEvolution.set(748);
        _latestInEvolution.set(750);
        _latestInEvolution.set(752);
        _latestInEvolution.set(754);
        _latestInEvolution.set(756);
        _latestInEvolution.set(758);
        _latestInEvolution.set(760);
        _latestInEvolution.set(763);
        _latestInEvolution.set(768);
        _latestInEvolution.set(770);
        _latestInEvolution.set(771);
        _latestInEvolution.set(773);
        _latestInEvolution.set(774);
        _latestInEvolution.set(775);
        _latestInEvolution.set(776);
        _latestInEvolution.set(777);
        _latestInEvolution.set(778);
        _latestInEvolution.set(779);
        _latestInEvolution.set(780);
        _latestInEvolution.set(781);
        _latestInEvolution.set(784);
        _latestInEvolution.set(785);
        _latestInEvolution.set(786);
        _latestInEvolution.set(787);
        _latestInEvolution.set(788);
        _latestInEvolution.set(791);
        _latestInEvolution.set(792);
        _latestInEvolution.set(793);
        _latestInEvolution.set(794);
        _latestInEvolution.set(795);
        _latestInEvolution.set(796);
        _latestInEvolution.set(797);
        _latestInEvolution.set(798);
        _latestInEvolution.set(799);

        _latestInEvolution.set(800);
        _latestInEvolution.set(801);
        _latestInEvolution.set(802);
        _latestInEvolution.set(804);
        _latestInEvolution.set(805);
        _latestInEvolution.set(806);
        _latestInEvolution.set(807);
        _latestInEvolution.set(809);
        _latestInEvolution.set(812);
        _latestInEvolution.set(815);
        _latestInEvolution.set(818);
        _latestInEvolution.set(820);
        _latestInEvolution.set(823);
        _latestInEvolution.set(826);
        _latestInEvolution.set(828);
        _latestInEvolution.set(830);
        _latestInEvolution.set(832);
        _latestInEvolution.set(834);
        _latestInEvolution.set(836);
        _latestInEvolution.set(839);
        _latestInEvolution.set(842);
        _latestInEvolution.set(844);
        _latestInEvolution.set(845);
        _latestInEvolution.set(847);
        _latestInEvolution.set(849);
        _latestInEvolution.set(851);
        _latestInEvolution.set(853);
        _latestInEvolution.set(855);
        _latestInEvolution.set(858);
        _latestInEvolution.set(861);
        _latestInEvolution.set(862);
        _latestInEvolution.set(863);
        _latestInEvolution.set(864);
        _latestInEvolution.set(865);
        _latestInEvolution.set(866);
        _latestInEvolution.set(867);
        _latestInEvolution.set(868);
        _latestInEvolution.set(869);
        _latestInEvolution.set(870);
        _latestInEvolution.set(871);
        _latestInEvolution.set(873);
        _latestInEvolution.set(874);
        _latestInEvolution.set(875);
        _latestInEvolution.set(876);
        _latestInEvolution.set(877);
        _latestInEvolution.set(879);
        _latestInEvolution.set(880);
        _latestInEvolution.set(881);
        _latestInEvolution.set(882);
        _latestInEvolution.set(883);
        _latestInEvolution.set(884);
        _latestInEvolution.set(887);
        _latestInEvolution.set(888);
        _latestInEvolution.set(889);
        _latestInEvolution.set(890);
        _latestInEvolution.set(892);
        _latestInEvolution.set(893);
        _latestInEvolution.set(894);
        _latestInEvolution.set(895);
        _latestInEvolution.set(896);
        _latestInEvolution.set(897);
        _latestInEvolution.set(898);
        _latestInEvolution.set(899);
        _latestInEvolution.set(900);
        _latestInEvolution.set(901);
        _latestInEvolution.set(902);
        _latestInEvolution.set(903);
        _latestInEvolution.set(904);
        _latestInEvolution.set(905);

        _thunderEvolutions[25] = 26;
        _thunderEvolutions[133] = 135;
        _thunderEvolutions[603] = 604;
        _moonEvolutions[30] = 31;
        _moonEvolutions[33] = 34;
        _moonEvolutions[35] = 36;
        _moonEvolutions[39] = 40;
        _moonEvolutions[300] = 301;
        _moonEvolutions[517] = 518;
        _fireEvolutions[37] = 38;
        _fireEvolutions[58] = 59;
        _fireEvolutions[513] = 514;
        _fireEvolutions[133] = 136;
        _leafEvolutions[44] = 45;
        _leafEvolutions[70] = 71;
        _leafEvolutions[102] = 103;
        _leafEvolutions[274] = 275;
        _leafEvolutions[511] = 512;
        _leafEvolutions[133] = 470;
        _sunEvolutions[44] = 182;
        _sunEvolutions[191] = 192;
        _sunEvolutions[546] = 547;
        _sunEvolutions[548] = 549;
        _sunEvolutions[694] = 695;
        _waterEvolutions[61] = 62;
        _waterEvolutions[90] = 91;
        _waterEvolutions[120] = 121;
        _waterEvolutions[271] = 272;
        _waterEvolutions[515] = 516;
        _waterEvolutions[133] = 134;
        _blackAuguriteEvolutions[123] = 900;
        _shinyEvolutions[176] = 468;
        _shinyEvolutions[315] = 407;
        _shinyEvolutions[572] = 573;
        _shinyEvolutions[670] = 671;
        _duskEvolutions[198] = 430;
        _duskEvolutions[200] = 429;
        _duskEvolutions[608] = 609;
        _duskEvolutions[680] = 681;
        _razorClawEvolutions[215] = 461;
        _peatBlockEvolutions[217] = 901;
        _tartAppleEvolutions[840] = 841;
        _crackedPotEvolutions[854] = 855;
        _ovalEvolutions[440] = 113;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}