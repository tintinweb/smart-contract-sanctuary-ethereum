//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// Interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../IBot.sol";
import "../IBotMetadata.sol";
import "./IFuseCalculator.sol";
import "../IERC20Burnable.sol";
import "../ITokenPaymentSplitter.sol";

// Dependencies
import "../Managable.sol";
import "../LibBot.sol";

contract ShipFuser is Managable {
    address public botAddress;
    address public botMetadataAddress;
    address public shipAddress;
    address public shipMetadataAddress;
    address public treasuryAddress;
    address public oilAddress;
    address public fuseCalculatorAddress;
    address public shipRevealerAddress;

    uint32 public revealCooldown = 0;
    uint32 public shipClassPrice = 60;

    mapping(address => uint32[]) public tokenPrices;
    mapping(address => uint256) public tokenDecimals;
    mapping(address => ShipsToReveal) public shipsToReveal;

    struct ShipsToReveal {
        uint32 revealTime;
        uint16[3] ships;
    }

    // events
    event ChangedBotAddress(address _addr);
    event ChangedBotMetadataAddress(address _addr);
    event ChangedTreasuryAddress(address _addr);
    event ChangedOilAddress(address _addr);
    event ChangedShipRevealerAddress(address _addr);
    event ChangedFuseCalculator (address _addr);
    event ChangedRevealCooldown(uint32 _cooldown);
    event ChangedShipClassPrice(uint32 _price);
    event AddedPaymentToken(address _addr, uint256 _decimals);
    event RemovedPaymentToken(address _addr);
    event ShipsFused(address indexed _owner, uint256 _oilPrice, address _token, uint256 _tokenPrice, uint16[3] _ships);

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
    
    function breed(uint256[] memory _botIds, address _token) external returns(uint256 totalShipsFused) {
        address _sender = msg.sender;
        require(_botIds.length >= 1, "no bots");
        require(_botOwnerNotSameBots(_botIds, _sender), "bots:same or not owner");
        require(shipsToReveal[_sender].revealTime == 0, "already fusing");

        (uint256 _tokenPrice, uint256 _oilPrice) = breedPrices(_botIds.length, _token);

        uint[3] memory class = _calculateClass(_botIds);
        uint[4] memory ships = _getShipsFromClass(class);
        require(ships[3] > 0, "not enough bots' class");

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
        shipEggs.ships[0] = uint16(ships[0]); 
        shipEggs.ships[1] = uint16(ships[1]); 
        shipEggs.ships[2] = uint16(ships[2]);
        shipsToReveal[_sender] = shipEggs; 

        emit ShipsFused(
            _sender,
            _oilPrice, 
            _token, 
            _tokenPrice,
            shipEggs.ships
        );

        return ships[3];
    }

    function breedPrices(
        uint256 _botNumber, 
        address _token
    ) public view returns(uint256 _tokenPrice, uint256 _oilPrice) {
        // Calculating primary price
        _tokenPrice = uint(tokenPrices[_token][_botNumber-1]);
        uint256 _tokenDecimals = tokenDecimals[_token];
        require(_tokenPrice > 0 && _tokenDecimals > 0);
        _tokenPrice *= _tokenDecimals;

        //Calculating oil price
        address _oilAddress = oilAddress;
        _oilPrice = uint(tokenPrices[_oilAddress][_botNumber-1]);
        uint256 _oilDecimals = tokenDecimals[_oilAddress];
        require(_oilPrice > 0 && _oilDecimals > 0);
        _oilPrice *= _oilDecimals;

        return (_tokenPrice, _oilPrice);
    }

    function revealShips (address _owner) public returns(ShipsToReveal memory _shipsToReveal){
        require(msg.sender == shipRevealerAddress, "Not Ship Revealer");
        _shipsToReveal = shipsToReveal[_owner];
        require(_shipsToReveal.revealTime > 0, "No Ships to reveal");
        require(block.timestamp > _shipsToReveal.revealTime, "Cooldown not passed");
        delete(shipsToReveal[_owner]);
        return shipsToReveal[_owner];
    }

    function getShipsToReveal (address _owner) public view returns(ShipsToReveal memory _shipsToReveal){
        return shipsToReveal[_owner];
    }
    
    
    function canFuse(uint256[] memory _botIds, address _owner) public view returns(bool) {
        if(_botIds.length < 1){return false;}
        if(shipsToReveal[_owner].revealTime != 0){return false;}
        if(_botOwnerNotSameBots(_botIds, _owner) == false){return false;}

        uint[3] memory class = _calculateClass(_botIds);
        uint[4] memory ships = _getShipsFromClass(class);
        if(ships[3] < 1){return false;}
        return true;
    }
     
    function calculateShips(uint256[] calldata _botIds) external view returns(uint[3] memory _ships){
        uint[3] memory class = _calculateClass(_botIds);
        uint[4] memory ships = _getShipsFromClass(class);
        _ships[0] = ships[0];
        _ships[1] = ships[1];
        _ships[2] = ships[2];
        return _ships;
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

    function setShipClassPrice(uint32 _price) external onlyManager {
        shipClassPrice = _price;
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

    function _bot() private view returns(IBot) {
        return IBot(botAddress);
    }

    function _botMetadata() private view returns(IBotMetadata) {
        return IBotMetadata(botMetadataAddress);
    }

    function _calculateClass(uint256[] memory _botIds) private view returns(uint[3] memory _totalClass){
        for (uint i = 0; i < _botIds.length; i++){
            uint gene = _botMetadata().getBot(_botIds[i]).genes;
            uint[3] memory class = IFuseCalculator(fuseCalculatorAddress).getClass(gene);
            _totalClass[0] += class[0];
            _totalClass[1] += class[1];
            _totalClass[2] += class[2]; 
        }
        return _totalClass;
    }

    function _getShipsFromClass(uint[3] memory _class) private view  returns(uint[4] memory _ships){
        _ships[0] = _class[0]/shipClassPrice;
        _ships[1] = _class[1]/shipClassPrice;
        _ships[2] = _class[2]/shipClassPrice;

        // calculating total number of ships
        for(uint i = 0; i <3; i++){
            _ships[3] += _ships[i];
        }
        return _ships;
    }

    function _botOwnerNotSameBots(uint256[] memory _botIds, address _owner) private view returns(bool) {
        if(_botIds.length > 1){
            for (uint i = 0; i < _botIds.length-1; i++){
                if(_bot().ownerOf(_botIds[i]) != _owner){
                    return false;
                }    
                for(uint j = i+1; j < _botIds.length; j++){
                    if(_botIds[i] == _botIds[j]){
                        return false;
                    }
                }
            }
        }
        if(_bot().ownerOf(_botIds[_botIds.length-1]) != _owner){
            return false;
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
    function getClass(uint _genes) external pure returns (uint[3] memory _botClass) ;
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