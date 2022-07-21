//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// Interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../IBot.sol";
import "../IBotMetadata.sol";
import "./IFuseCalculator.sol";
import "../IERC20Burnable.sol";
import "../ITokenPaymentSplitter.sol";

// Dependencies
import "../Managable.sol";
import "../LibBot.sol";

contract ShipFuser is Managable, Pausable {
    address public botAddress;
    address public botMetadataAddress;
    address public shipAddress;
    address public shipMetadataAddress;
    address public treasuryAddress;
    address public oilAddress;
    address public fuseCalculatorAddress;
    address public shipRevealerAddress;

    uint32 public revealCooldown = 0;
    uint32 public shipClassNumber = 3;
    uint32[] public shipClassPrices = [10, 10, 10];

    mapping(address => uint32[]) public tokenPrices;
    mapping(address => uint256) public tokenDecimals;
    mapping(address => ShipsToReveal) public shipsToReveal;

    struct ShipsToReveal {
        uint32 revealTime;
        uint16[] ships;
    }

    // events
    event ChangedBotAddress(address _addr);
    event ChangedBotMetadataAddress(address _addr);
    event ChangedTreasuryAddress(address _addr);
    event ChangedOilAddress(address _addr);
    event ChangedShipRevealerAddress(address _addr);
    event ChangedFuseCalculator (address _addr);
    event ChangedRevealCooldown(uint32 _cooldown);
    event ChangedShipClassNumber(uint32 _classNumber);
    event ChangedShipClassPrice(uint32[] _price);
    event AddedPaymentToken(address _addr, uint256 _decimals);
    event RemovedPaymentToken(address _addr);
    event ShipsFused(address indexed _owner, uint256 _oilPrice, address _token, uint256 _tokenPrice, uint32 _revealTime, uint16[] _ships);

    constructor(
        address _botAddress,
        address _botMetadataAddress,
        address _treasuryAddress,
        address _oilAddress,
        address _fuseCalculatorAddress,
        address _shipRevealerAddress
    ) {
        _setBotAddress(_botAddress);
        _setBotMetadataAddress(_botMetadataAddress);
        _setTreasuryAddress(_treasuryAddress);
        _setOilAddress(_oilAddress);
        _setFuseCalculatorAddress(_fuseCalculatorAddress);
        _setShipRevealerAddress(_shipRevealerAddress);
        _addManager(msg.sender);
    }
    
    function fuse(uint256[] memory _botIds, address _token) whenNotPaused external returns(uint256 totalShipsFused) {
        address _sender = msg.sender;
        require(_botIds.length >= 1, "no bots");
        require(_botIds.length <= 100, "too much bots");
        require(_botOwner(_botIds, _sender), "bots:not owner");
        require(shipsToReveal[_sender].revealTime == 0, "already fusing");

        uint _shipClassNumber = uint(shipClassNumber);
        (uint[] memory class, bool fullGenes) = _calculateClass(_botIds, _shipClassNumber);
        require(fullGenes == true, "bots:empty or not revealed");
        (uint16[] memory ships, uint totalShips) = _getShipsFromClass(class, _shipClassNumber);
        require(totalShips > 0, "not enough bots' class");
        (uint256 _tokenPrice, uint256 _oilPrice) = getFusePrices(totalShips, _token);

        // Transfering payments
        require(IERC20(_token).transferFrom(_sender, address(this), _tokenPrice));
        IERC20(_token).approve(treasuryAddress, _tokenPrice);
        ITokenPaymentSplitter(treasuryAddress).split(_token, _sender, _tokenPrice);
        
        // Burning tokens
        IERC20Burnable(oilAddress).burnFrom(_sender, _oilPrice);
        
        //Burn bots
        _burnBots(_botIds);

        //Saving data for reveal

        ShipsToReveal memory shipEggs;
        shipEggs.revealTime = uint32(block.timestamp) + revealCooldown;
        shipEggs.ships = ships;
        shipsToReveal[_sender] = shipEggs; 

        emit ShipsFused(
            _sender,
            _oilPrice, 
            _token, 
            _tokenPrice,
            shipEggs.revealTime,
            shipEggs.ships
        );

        return totalShips;
    }

    function revealShips (address _owner) whenNotPaused public returns(ShipsToReveal memory _shipsToReveal) {
        require(msg.sender == shipRevealerAddress, "Not Ship Revealer");
        _shipsToReveal = shipsToReveal[_owner];
        require(_shipsToReveal.revealTime > 0, "No Ships to reveal");
        require(block.timestamp > _shipsToReveal.revealTime, "Cooldown not passed");
        delete(shipsToReveal[_owner]);
        return _shipsToReveal;
    }

    function getFusePrices(
        uint256 _shipNumber, 
        address _token
    ) public view returns(uint256 _tokenPrice, uint256 _oilPrice) {
        // Calculating primary price
        uint256 _tokenDecimals = tokenDecimals[_token];
        require(_shipNumber <= tokenPrices[_token].length && _tokenDecimals > 0, "not allowed");
        _tokenPrice = uint(tokenPrices[_token][_shipNumber-1]);
        _tokenPrice *= _tokenDecimals;

        //Calculating oil price
        address _oilAddress = oilAddress;
        uint256 _oilDecimals = tokenDecimals[_oilAddress];
        require(_shipNumber <= tokenPrices[_oilAddress].length && _oilDecimals > 0, "not allowed");
        _oilPrice = uint(tokenPrices[_oilAddress][_shipNumber-1]);
        _oilPrice *= _oilDecimals;

        return (_tokenPrice, _oilPrice);
    }
    
    function canFuse(uint256[] memory _botIds, address _owner) public view returns(bool) {
        if(_botIds.length < 1){return false;}
        if(shipsToReveal[_owner].revealTime != 0){return false;}
        if(_botOwner(_botIds, _owner) == false){return false;}

        (uint[] memory class, bool fullGenes) = _calculateClass(_botIds, shipClassNumber);
        if(fullGenes == false){return false;}
        (, uint totalShips) = _getShipsFromClass(class, shipClassNumber);
        if(totalShips < 1){return false;}
        return true;
    }
     
    function calculateShips(uint256[] calldata _botIds) external view returns(uint16[] memory _ships){
        (uint[] memory class, bool fullGenes) = _calculateClass(_botIds, shipClassNumber);
        require(fullGenes == true, "bots:empty or not revealed");
        (uint16[] memory ships,) = _getShipsFromClass(class, shipClassNumber);
        return ships;
    }

    function getShipsToReveal (address _owner) public view returns(ShipsToReveal memory _shipsToReveal){
        return shipsToReveal[_owner];
    }
    
    function getTokenPrices (address _token) public view returns(uint32[] memory _tokenPrices){
        return tokenPrices[_token];
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

    function setFuseCalculatorAddress(address _addr) external onlyManager {
        _setFuseCalculatorAddress(_addr);
    }       
    
    function setShipRevealerAddress(address _addr) external onlyManager {
        _setShipRevealerAddress(_addr);
    }       

    function setRevealCooldown(uint32 _cooldown) external onlyManager {
        revealCooldown = _cooldown;
        emit ChangedRevealCooldown(_cooldown);
    }

    function setShipClassNumber(uint32 _classNumber) external onlyManager {
        shipClassNumber = _classNumber;
        emit ChangedShipClassNumber(_classNumber);
    }
    

    function setShipClassPrice(uint32[] calldata _price) external onlyManager {
        for (uint i=0; i < _price.length; i++){
            shipClassPrices[i] = _price[i];
        }
        if(shipClassPrices.length > _price.length){
            for (uint i=_price.length; i < shipClassPrices.length; i++){
                delete(shipClassPrices[i]);
            }
        }
        emit ChangedShipClassPrice(_price);
    }

    function addPayToken(address _addr, uint32[] memory _prices, uint256 _decimals) external onlyManager {
        for (uint i = 0; i < _prices.length; i++){
            tokenPrices[_addr].push(_prices[i]);
        }
        tokenDecimals[_addr] = _decimals;
        emit AddedPaymentToken(_addr, _decimals);
    }

    function removePayToken(address _addr) external onlyManager {
        uint length = tokenPrices[_addr].length;
        for (uint i = 0; i < length; i++){
            tokenPrices[_addr].pop();
        }
        tokenDecimals[_addr] = 0;
        emit RemovedPaymentToken(_addr);
    }
    
    function pause() external onlyManager {
        _pause();
    }

    function unpause() external onlyManager {
        _unpause();
    }            

    function _bot() private view returns(IBot) {
        return IBot(botAddress);
    }

    function _botMetadata() private view returns(IBotMetadata) {
        return IBotMetadata(botMetadataAddress);
    }

    function _calculateClass(uint256[] memory _botIds, uint _shipClassNumber) private view returns(uint[] memory, bool fullGenes){

        fullGenes = true;
        uint[] memory _totalClass = new uint[](_shipClassNumber);

        for (uint i = 0; i < _botIds.length; i++){
            uint gene = _botMetadata().getBot(_botIds[i]).genes;
            if(gene == 0){fullGenes = false;}
            uint[] memory class = IFuseCalculator(fuseCalculatorAddress).getClass(gene, _shipClassNumber);
            for(uint j=0; j < _shipClassNumber; j++){
                _totalClass[j] += class[j];
            }
        }
        return (_totalClass, fullGenes);
    }

    function _getShipsFromClass(uint[] memory _class, uint _shipClassNumber) private view  returns(uint16[] memory, uint totalShips){

        totalShips = 0;
        uint16[] memory _ships = new uint16[](_shipClassNumber);

        for (uint i = 0; i< _shipClassNumber; i++){
            _ships[i] = uint16(_class[i]/shipClassPrices[i]);
            totalShips += _ships[i];
        }

        return (_ships, totalShips);
    }

    function _botOwner(uint256[] memory _botIds, address _owner) private view returns(bool) {
        for (uint i = 0; i < _botIds.length; i++){
                if(_bot().ownerOf(_botIds[i]) != _owner){
                    return false;
                }    
        }
        return true;
    }

    function _burnBots(uint256[] memory _botIds) private {
        for (uint i = 0; i < _botIds.length; i++){
            _bot().burn(_botIds[i]);
        }
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

    function _setFuseCalculatorAddress(address _addr) internal {
        fuseCalculatorAddress = _addr;
        emit ChangedFuseCalculator(_addr);
    }   
    
    function _setOilAddress(address _addr) internal {
        oilAddress = _addr;
        emit ChangedOilAddress(_addr);
    }

    function _setShipRevealerAddress(address _addr) internal {
        shipRevealerAddress = _addr;
        emit ChangedShipRevealerAddress(_addr);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBot is IERC721 {
    function mint(address _to) external returns(uint256);
    function mintTokenId(address _to, uint256 _tokenId) external;
    function burn(uint256 tokenId) external;
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

interface IFuseCalculator {
    function getClass(uint _genes, uint _classNumber) external pure returns (uint[] memory _botClass) ;
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

    function from(Bot calldata bot) public pure returns (uint256[] memory) {
        uint256[] memory _data = new uint256[](9);
        _data[0] = bot.id;
        _data[1] = bot.genes;
        _data[2] = bot.birthTime;
        _data[3] = uint256(bot.matronId);
        _data[4] = uint256(bot.sireId);
        _data[5] = uint256(bot.generation);
        _data[6] = uint256(bot.breedCount);
        _data[7] = bot.lastBreed;
        _data[8] = bot.revealCooldown;

        return _data;
    }

    function into(uint256[] calldata data) public pure returns (Bot memory) {
        Bot memory bot = Bot({
            id: data[0],
            genes: data[1],
            birthTime: data[2],
            matronId: uint64(data[3]),
            sireId: uint64(data[4]),
            generation: uint8(data[5]),
            breedCount: uint8(data[6]),
            lastBreed: data[7],
            revealCooldown: data[8]      
        });

        return bot;
    }    
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