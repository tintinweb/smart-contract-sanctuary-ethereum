//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Interfaces
import "./IBot.sol";
import "./IBotMetadata.sol";
import "./IERC20Burnable.sol";
import "./ITokenPaymentSplitter.sol";

// Dependencies
import "./Managable.sol";
import "./LibBot.sol";

contract BotMinter is Managable {
    address public botAddress;
    address public botMetadataAddress;
    address public treasuryAddress;
    address public oilAddress;

    uint32[] public cooldowns = [
        uint32(1 minutes),
        uint32(2 minutes),
        uint32(5 minutes),
        uint32(10 minutes),
        uint32(30 minutes),
        uint32(1 hours),
        uint32(2 hours),
        uint32(4 hours),
        uint32(8 hours),
        uint32(16 hours),
        uint32(1 days),
        uint32(2 days),
        uint32(4 days),
        uint32(7 days)
    ];
    mapping(address => uint32) public tokenPrices;
    mapping(address => uint256) public tokenDecimals;

    uint32[] public oilPrices = [
        250,
        270,
        300,
        350,
        400,
        450,
        500,
        500,
        500,
        500,
        500,
        500,
        500
    ];
    uint256 oilDecimals = 10 ** 18;

    uint32 public revealCooldown = uint32(5 days);

    // events
    event ChangedBotAddress(address _addr);
    event ChangedBotMetadataAddress(address _addr);
    event ChangedTreasuryAddress(address _addr);
    event ChangedOilAddress(address _addr);
    event ChangedRevealCooldown(uint32 _cooldown);
    event ChangedCooldowns(uint32[] _cooldowns);
    event ChangedOilPrices(uint32[] _prices, uint32 _decimals);
    event AddedPaymentToken(address _addr, uint32 _price, uint256 _decimals);
    event RemovedPaymentToken(address _addr);
    event BotBreed(uint256 indexed _tokenId, uint256 indexed _matronId, uint256 indexed _sireId, uint256 _oilPrice, address _token, uint256 _tokenPrice);

    constructor(
        address _botAddress,
        address _botMetadataAddress,
        address _treasuryAddress,
        address _oilAddress
    ) {
        _setBotAddress(_botAddress);
        _setBotMetadataAddress(_botMetadataAddress);
        _setTreasuryAddress(_treasuryAddress);
        _setOilAddress(_oilAddress);

        _addManager(msg.sender);
    }

    function setCooldowns(uint32[] calldata _cooldowns) external onlyManager {
        cooldowns = _cooldowns;
        emit ChangedCooldowns(_cooldowns);
    }

    function setOilPrices(uint32[] calldata _prices, uint32 _decimals) external onlyManager {
        oilPrices = _prices;
        oilDecimals = _decimals;
        emit ChangedOilPrices(_prices, _decimals);
    }             

    function setBotAddress(address _addr) external onlyManager {
        _setBotAddress(_addr);
    }

    function setBotMetadataAddress(address _addr) external onlyManager {
        _setBotMetadataAddress(_addr);
    }    

    function setTreasuryAddress(address _addr) external onlyManager {
        _setTreasuryAddress(_addr);
    }   

    function setOilAddress(address _addr) external onlyManager {
        _setOilAddress(_addr);
    }      

    function setRevealCooldown(uint32 _cooldown) external onlyManager {
        revealCooldown = _cooldown;
        emit ChangedRevealCooldown(_cooldown);
    }

    function addPayToken(address _addr, uint32 _price, uint256 _decimals) external onlyManager {
        tokenPrices[_addr] = _price;
        tokenDecimals[_addr] = _decimals;
        emit AddedPaymentToken(_addr, _price, _decimals);
    }

    function removePayToken(address _addr) external onlyManager {
        tokenPrices[_addr] = 0;
        tokenDecimals[_addr] = 0;
        emit RemovedPaymentToken(_addr);
    }    
    
    function breed(uint256 _matronId, uint256 _sireId, address _token) external {
        address _sender = msg.sender;
        require(_matronId != _sireId, "matron,sire:same");
        require(_bot().ownerOf(_matronId) == _sender, "not owner");
        require(_bot().ownerOf(_sireId) == _sender, "not owner");    

        LibBot.Bot memory matron = _botMetadata().getBot(_matronId);
        LibBot.Bot memory sire = _botMetadata().getBot(_sireId);

        require(_canBreed(matron), "matron:lim");
        require(_canBreed(sire), "sire:lim");
        require(_notCooldown(matron), "matron:cd");
        require(_notCooldown(sire), "sire:cd");
        require(_notRelatives(matron, sire), "relatives");      

        (
            uint256 _tokenPrice, 
            uint256 _matronPrice, 
            uint256 _sirePrice
        ) = _breedPrices(matron, sire, _token);

        // Transfering payments
        require(IERC20(_token).transferFrom(_sender, address(this), _tokenPrice));
        IERC20(_token).approve(treasuryAddress, _tokenPrice);
        ITokenPaymentSplitter(treasuryAddress).split(_token, _sender, _tokenPrice);
        
        // Burning tokens
        IERC20Burnable(oilAddress).burnFrom(_sender, _matronPrice + _sirePrice);

        // Calculating reveal cooldown
        uint32 _rCooldown = revealCooldown;
        if (matron.generation == 0 && sire.generation == 0) {
            _rCooldown = _rCooldown / 2;
        }

        // Creating a new bot
        uint256 tokenId = _bot().mint(_sender);
        LibBot.Bot memory bot;
        bot.id = tokenId;
        bot.generation = 1;
        bot.matronId = uint64(_matronId);
        bot.sireId = uint64(_sireId);
        bot.revealCooldown = block.timestamp + _rCooldown;
        _botMetadata().setBot(tokenId, bot);

        // Increasing breed amount for matron
        matron.breedCount += 1;
        matron.lastBreed = block.timestamp;
        _botMetadata().setBot(_matronId, matron);

        // Increasing breed amount for sire
        sire.breedCount += 1;
        sire.lastBreed = block.timestamp;
        _botMetadata().setBot(_sireId, sire);

        emit BotBreed(
            tokenId, 
            _matronId,
            _sireId,
            _matronPrice + _sirePrice, 
            _token, 
            _tokenPrice
        );
    }

    function mintGenesisTokenId(address _to, uint256 _tokenId, uint256 _dna) external onlyManager {
        LibBot.Bot memory bot = _blankBot(_dna);

        _bot().mintTokenId(_to, _tokenId);
        bot.id = _tokenId;
        _botMetadata().setBot(_tokenId, bot);  
    }

    function mintGenesis(address _to, uint256 _dna) external onlyManager {
        LibBot.Bot memory bot = _blankBot(_dna);

        uint256 _tokenId = _bot().mint(_to);
        bot.id = _tokenId;
        _botMetadata().setBot(_tokenId, bot);
    }

    function _blankBot(uint256 _dna) internal view returns(LibBot.Bot memory) {
        LibBot.Bot memory bot;
        bot.genes = _dna;
        bot.generation = 0;
        bot.breedCount = 0;
        bot.birthTime = block.timestamp;
        bot.lastBreed = 0;
        bot.matronId = 0;
        bot.sireId = 0;
        bot.revealCooldown = 0;

        return bot;
    }

    function breedPrices(uint256 _matronId, uint256 _sireId, address _token) public view returns(uint256, uint256, uint256) {
        LibBot.Bot memory matron = _botMetadata().getBot(_matronId);
        LibBot.Bot memory sire = _botMetadata().getBot(_sireId);        

        return _breedPrices(matron, sire, _token);
    }
    
    function _breedPrices(LibBot.Bot memory matron, LibBot.Bot memory sire, address _token) internal view returns(uint256, uint256, uint256) {
        // Calculating primary price
        uint32 _tokenPrice = tokenPrices[_token];
        uint256 _tokenDecimals = tokenDecimals[_token];
        require(_tokenPrice > 0 && _tokenDecimals > 0);

        // Calculating oitPrices
        uint256 matronPrice = oilPrices[matron.breedCount] * oilDecimals;
        uint256 sirePrice = oilPrices[sire.breedCount] * oilDecimals;

        return (_tokenPrice * _tokenDecimals, matronPrice, sirePrice);
    }

    function canBreed(uint256 _matronId, uint256 _sireId) public view returns(bool) {
        if (_matronId == _sireId) {
            return false;
        }

        LibBot.Bot memory matron = _botMetadata().getBot(_matronId);
        LibBot.Bot memory sire = _botMetadata().getBot(_sireId);

        return _canBreed(matron) && _canBreed(sire) && _notCooldown(matron) && _notCooldown(sire) && _notRelatives(matron, sire);
    }

    function canBreedMultiple(uint256 _matronId, uint256[] calldata _siresIds) public view returns(bool[] memory) {
        bool[] memory _canBreedWith = new bool[](_siresIds.length);
        for(uint256 i = 0; i < _siresIds.length; i++) {
            _canBreedWith[i] = canBreed(_matronId, _siresIds[i]);
        }

        return _canBreedWith;
    }

    function _bot() private view returns(IBot) {
        return IBot(botAddress);
    }

    function _botMetadata() private view returns(IBotMetadata) {
        return IBotMetadata(botMetadataAddress);
    }

    function _notCooldown(LibBot.Bot memory _b) private view returns(bool) {
        if (_b.breedCount == 0) {
            return true;
        }

        uint32 _cooldown = cooldowns[_b.breedCount];
        if (_cooldown == 0) {
            return true;
        }

        return _b.lastBreed + _cooldown < block.timestamp;
    }

    function _canBreed(LibBot.Bot memory _b) private pure returns(bool) {
        if (_b.generation == 0 && _b.breedCount <= 12) {
            return true;
        }

        return _b.breedCount <= 7;
    }

    function _notRelatives(LibBot.Bot memory _matron, LibBot.Bot memory _sire) private pure returns(bool) {        
        if (_matron.generation == 0 && _sire.generation == 0) {
            return true;
        }
        
        // If they have same partens it's can't be done
        if (
            (_matron.matronId == _sire.matronId && _matron.sireId == _sire.sireId) || 
            (_matron.sireId == _sire.matronId && _matron.matronId == _sire.sireId)
        ) {
            return false;
        }

        // You can't breed with you kids
        if (_matron.id == _sire.matronId || _matron.id == _sire.sireId) {
            return false;
        }

        if (_sire.id == _matron.matronId || _sire.id == _matron.sireId) {
            return false;
        }

        return true;
    }

    function _setBotAddress(address _addr) internal {
        botAddress = _addr;
        emit ChangedBotAddress(_addr);
    }

    function _setBotMetadataAddress(address _addr) internal {
        botMetadataAddress = _addr;
        emit ChangedBotMetadataAddress(_addr);
    }    

    function _setTreasuryAddress(address _addr) internal {
        treasuryAddress = _addr;
        emit ChangedTreasuryAddress(_addr);
    }   

    function _setOilAddress(address _addr) internal {
        oilAddress = _addr;
        emit ChangedOilAddress(_addr);
    }          
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBot is IERC721 {
    function mint(address _to) external returns(uint256);
    function mintTokenId(address _to, uint256 _tokenId) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./LibBot.sol";

interface IBotMetadata {
    function setBot(uint256 _tokenId, LibBot.Bot calldata _bot) external;
    function getBot(uint256 _tokenId) external view returns(LibBot.Bot memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ITokenPaymentSplitter {
    function split(address _token, address _sender, uint256 _amount) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Managable {
    mapping(address => bool) private managers;

    event AddedManager(address _address);
    event RemovedManager(address _address);

    modifier onlyManager() {
        require(managers[msg.sender], "caller is not manager");
        _;
    }

    function addManager(address _manager) external onlyManager {
        _addManager(_manager);
    }

    function removeManager(address _manager) external onlyManager {
        _removeManager(_manager);
    }

    function _addManager(address _manager) internal {
        managers[_manager] = true;
        emit AddedManager(_manager);
    }

    function _removeManager(address _manager) internal {
        managers[_manager] = false;
        emit RemovedManager(_manager);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library LibBot {
    struct Bot {
        uint256 id;
        uint256 genes;
        uint256 birthTime;
        uint64 matronId;
        uint64 sireId;
        uint8 generation;
        uint8 breedCount;
        uint256 lastBreed;
        uint256 revealCooldown;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
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