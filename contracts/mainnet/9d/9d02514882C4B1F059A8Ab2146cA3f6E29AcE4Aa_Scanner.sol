/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC721.sol";
import "Ownable.sol";
import "ISheetFighterToken.sol";
import "ICellToken.sol";
import "IPortal.sol";


/// @title Contract to send Sheet Fighters and $CELL between Ethereum and Polygon
/// @author Overlord Paper Co.
/// @notice A big thank you to 0xBasset from EtherOrcs! This contract is heavily influenced
/// @notice by the the EtherOrcs Ethereum <--> Polygon bridge, and 0xBasset was a great
/// @notice sounding board during development.
contract Scanner is Ownable {
    address public portal;
    address public sheetFighterToken;
    address public cellToken;
    mapping (address => address) public reflection;
    mapping (uint256 => address) public sheetOwner;

    constructor() Ownable() {}

    modifier onlyPortal() {
        require(portal != address(0), "Portal must be set");
        require(msg.sender == portal, "Only portal can do this");
        _;
    }


    /// @dev Initiatilize state for proxy contract
    /// @param portal_ Portal address
    /// @param sheetFighterToken_ SheetFighterToken address
    /// @param cellToken_ CellToken address
    function initialize(
        address portal_, 
        address sheetFighterToken_, 
        address cellToken_
    ) 
        external 
        onlyOwner
    {
        portal = portal_;
        sheetFighterToken = sheetFighterToken_;
        cellToken = cellToken_;
    }

    /// @dev Set Ethereum <--> Polygon reflection address
    /// @param key_ Address for contract on one network
    /// @param reflection_ Address for contract on sister network
    function setReflection(address key_, address reflection_) external onlyOwner {
        reflection[key_] = reflection_;
        reflection[reflection_] = key_;
    }

    /// @notice Bridge your Sheet Fighter(s) and $CELL between Ethereum and Polygon
    /// @notice This contract must be approved to transfer your Sheet Fighter(s) on your behalf
    /// @notice Sheet Fighter(s) must be in your wallet (i.e. not staked or bridged) to travel
    /// @param sheetFighterIds Ids of the Sheet Fighters being bridged
    /// @param cellAmount Amount of $CELL to bridge
    function travel(uint256[] calldata sheetFighterIds, uint256 cellAmount) external {
        require(sheetFighterIds.length > 0 || cellAmount > 0, "Can't bridge nothing");

        // Address of contract on the sister-chain
        address target = reflection[address(this)];

        uint256 numSheetFighters = sheetFighterIds.length;
        uint256 currIndex = 0;

        bytes[] memory calls = new bytes[]((numSheetFighters > 0 ? numSheetFighters + 1 : 0) + (cellAmount > 0 ? 1 : 0));

        // Handle Sheets
        if(numSheetFighters > 0 ) {
            // Transfer Sheets to bridge (SheetFighterToken contract then calls callback on this contract)
            _pullIds(sheetFighterToken, sheetFighterIds);

            // Recreate Sheets on sister-chain exact as they exist on this chain
            for(uint256 i = 0; i < numSheetFighters; i++) {
                calls[i] = _buildData(sheetFighterIds[i]);
            }

            calls[numSheetFighters] = abi.encodeWithSelector(this.unstakeMany.selector, reflection[sheetFighterToken], msg.sender, sheetFighterIds);

            currIndex += numSheetFighters + 1;
        }

        // Handle $CELL
        if(cellAmount > 0) {
            // Burn $CELL on this side of bridge
            ICellToken(cellToken).bridgeBurn(msg.sender, cellAmount);

            // Add call to mint $CELL on other side of bridge
            calls[currIndex] = abi.encodeWithSelector(this.mintCell.selector, reflection[cellToken], msg.sender, cellAmount);
        }

        // Send messages to portal
        IPortal(portal).sendMessage(abi.encode(target, calls));

    }

    /// @dev Callback function called by SheetFighterToken contract during travel
    /// @dev "Stakes" all Sheets being bridged to this contract (i.e. transfers custody to this contract)
    /// @param owner Address of the owner of the Sheet Fighters being bridged
    /// @param tokenIds Token ids of the Sheet Fighters being bridged
    function bridgeTokensCallback(address owner, uint256[] calldata tokenIds) external {
        require(msg.sender == sheetFighterToken, "Only SheetFighterToken contract can do this");

        for(uint256 i = 0; i < tokenIds.length; i++) {
            _stake(msg.sender, tokenIds[i], owner);
        }
    }

    /// @dev Unstake the Sheet Fighters from this contract and transfer ownership to owner
    /// @dev Called on the "to" network for bridging
    /// @param token Address of the ERC721 contract fot the tokens being bridged
    /// @param owner Address of the owner of the Sheet Fighters being bridged
    /// @param ids ERC721 token ids of the Sheet Fighters being bridged
    function unstakeMany(address token, address owner, uint256[] calldata ids) external onlyPortal {

        for (uint256 i = 0; i < ids.length; i++) {  
            delete sheetOwner[ids[i]];
            IERC721(token).transferFrom(address(this), owner, ids[i]);
        }
    }

    /// @dev Calls the SheetFighterToken contract with given calldata
    /// @dev This is used to execute the cross-chain function calls
    /// @param data Calldata with which to call SheetFighterToken
    function callSheets(bytes calldata data) external onlyPortal {
        (bool succ, ) = sheetFighterToken.call(data);
        require(succ);
    }

    /// @dev Mint $CELL on the "to" network
    /// @param token Address of CellToken contract
    /// @param to Address of user briding $CELL
    /// @param amount Amount of $CELL being bridged
    function mintCell(address token, address to, uint256 amount) external onlyPortal {
        ICellToken(token).bridgeMint(to, amount);
    }
    
    /// @dev Informs other contracts that this contract knows about ERC721s
    /// @dev Allows ERC721 safeTransfer and safeTransferFrom transactions to this contract
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @dev Call the bridgeSheets function on the "from" part of the network, which transfers tokens
    /// @param tokenAddress Address of SheetFighterToken contract
    /// @param tokenIds SheetFighterToken ids of Sheet Fighters being bridged
    function _pullIds(address tokenAddress, uint256[] calldata tokenIds) internal {
        // The ownership will be checked to the token contract
        ISheetFighterToken(tokenAddress).bridgeSheets(msg.sender, tokenIds);
    }

    /// @dev Set state variables mapping tokenId to owner
    /// @param token Address of ERC721 contract
    /// @param tokenId ERC721 id for token being staked
    /// @param owner Address of owner who is bridging
    function _stake(address token, uint256 tokenId, address owner) internal {
        require(sheetOwner[tokenId] == address(0), "Token already staked");
        require(msg.sender == token, "Not SF contract");
        require(IERC721(token).ownerOf(tokenId) == address(this), "Sheet not transferred");

        if (token == sheetFighterToken){ 
            sheetOwner[tokenId] = owner;
        }
    }

    /// @dev build calldata for transaction to update Sheet's stats
    /// @param id SheetFighterToken id
    function _buildData(uint256 id) internal view returns (bytes memory) {
        (uint8 hp, uint8 critical, uint8 heal, uint8 defense, uint8 attack, , ) = ISheetFighterToken(sheetFighterToken).tokenStats(id);
        bytes memory data = abi.encodeWithSelector(this.callSheets.selector, abi.encodeWithSelector(ISheetFighterToken.syncBridgedSheet.selector, id, hp, critical, heal, defense, attack));
        return data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC165.sol";

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

pragma solidity ^0.8.0;

import "Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

pragma solidity ^0.8.0;

import "IERC721Enumerable.sol";

interface ISheetFighterToken is IERC721Enumerable {

    /// @notice Update the address of the CellToken contract
    /// @param _contractAddress Address of the CellToken contract
    function setCellTokenAddress(address _contractAddress) external;

    /// @notice Update the address which signs the mint transactions
    /// @dev    Used for ensuring GPT-3 values have not been altered
    /// @param  _mintSigner New address for the mintSigner
    function setMintSigner(address _mintSigner) external;

    /// @notice Update the address of the bridge
    /// @dev Used for authorization
    /// @param  _bridge New address for the bridge
    function setBridge(address _bridge) external;

    /// @notice Update the address of the upgrade contract
    /// @dev Used for authorization
    /// @param  _upgradeContract New address for the upgrade contract
    function setUpgradeContract(address _upgradeContract) external;

    /// @dev Withdraw funds as owner
    function withdraw() external;

    /// @notice Set the sale state: options are 0 (closed), 1 (presale), 2 (public sale) -- only owner can call
    /// @dev    Implicitly converts int argument to TokenSaleState type -- only owner can call
    /// @param  saleStateId The id for the sale state: 0 (closed), 1 (presale), 2 (public sale)
    function setSaleState(uint256 saleStateId) external;

    /// @notice Mint up to 20 Sheet Fighters
    /// @param  numTokens Number of Sheet Fighter tokens to mint (1 to 20)
    function mint(uint256 numTokens) external payable;

    /// @notice "Print" a Sheet. Adds GPT-3 flavor text and attributes
    /// @dev    This function requires signature verification
    /// @param  _tokenIds Array of tokenIds to print
    /// @param  _flavorTexts Array of strings with flavor texts concatonated with a pipe character
    /// @param  _signature Signature verifying _flavorTexts are unmodified
    function print(
        uint256[] memory _tokenIds,
        string[] memory _flavorTexts,
        bytes memory _signature
    ) external;

    /// @notice Bridge the Sheets
    /// @dev Transfers Sheets to bridge
    /// @param tokenOwner Address of the tokenOwner who is bridging their tokens
    /// @param tokenIds Array of tokenIds that tokenOwner is bridging
    function bridgeSheets(address tokenOwner, uint256[] calldata tokenIds) external;

    /// @notice Update the sheet to sync with actions that occured on otherside of bridge
    /// @param tokenId Id of the SheetFighter
    /// @param HP New HP value
    /// @param critical New luck value
    /// @param heal New heal value
    /// @param defense New defense value
    /// @param attack New attack value
    function syncBridgedSheet(
        uint256 tokenId,
        uint8 HP,
        uint8 critical,
        uint8 heal,
        uint8 defense,
        uint8 attack
    ) external;

    /// @notice Get Sheet stats
    /// @param _tokenId Id of SheetFighter
    /// @return tuple containing sheet's stats
    function tokenStats(uint256 _tokenId) external view returns(uint8, uint8, uint8, uint8, uint8, uint8, uint8);

    /// @notice Return true if token is printed, false otherwise
    /// @param _tokenId Id of the SheetFighter NFT
    /// @return bool indicating whether or not sheet is printed
    function isPrinted(uint256 _tokenId) external view returns(bool);

    /// @notice Returns the token metadata and SVG artwork
    /// @dev    This generates a data URI, which contains the metadata json, encoded in base64
    /// @param _tokenId The tokenId of the token whos metadata and SVG we want
    function tokenURI(uint256 _tokenId) external view returns (string memory);

    /// @notice Update the sheet to via upgrade contract
    /// @param tokenId Id of the SheetFighter
    /// @param attributeNumber specific attribute to upgrade
    /// @param value new attribute value
    function updateStats(uint256 tokenId,uint8 attributeNumber,uint8 value) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";


/// @title  Contract creating fungible in-game utility tokens for the Sheet Fighter game
/// @author Overlord Paper Co
/// @notice This defines in-game utility tokens that are used for the Sheet Fighter game
/// @notice This contract is HIGHLY adapted from the Anonymice $CHEETH contract
/// @notice Thank you MouseDev for writing the original $CHEETH contract!
interface ICellToken is IERC20 {

    /// @notice Update the address of the SheetFighterToken contract
    /// @param _contractAddress Address of the SheetFighterToken contract
    function setSheetFighterTokenAddress(address _contractAddress) external;

    /// @notice Update the address of the bridge
    /// @dev Used for authorization
    /// @param  _bridge New address for the bridge
    function setBridge(address _bridge) external;

    /// @notice Stake multiple Sheets by providing their Ids
    /// @param tokenIds Array of SheetFighterToken ids to stake
    function stakeByIds(uint256[] calldata tokenIds) external;

    /// @notice Unstake all of your SheetFighterTokens and get your rewards
    /// @notice This function is more gas efficient than calling unstakeByIds(...) for all ids
    /// @dev Tokens are iterated over in REVERSE order, due to the implementation of _remove(...)
    function unstakeAll() external;

    /// @notice Unstake SheetFighterTokens, given by ids, and get your rewards
    /// @notice Use unstakeAll(...) instead if unstaking all tokens for gas efficiency
    /// @param tokenIds Array of SheetFighterToken ids to unstake
    function unstakeByIds(uint256[] memory tokenIds) external;

    /// @notice Claim $CELL tokens as reward for staking a SheetFighterTokens, given by an id
    /// @notice This function does not unstake your Sheets
    /// @param tokenId SheetFighterToken id
    function claimByTokenId(uint256 tokenId) external;

    /// @notice Claim $CELL tokens as reward for all SheetFighterTokens staked
    /// @notice This function does not unstake your Sheets
    function claimAll() external;

    /// @notice Mint tokens when bridging
    /// @dev This function is only used for bridging to mint tokens on one end
    /// @param to Address to send new tokens to
    /// @param value Number of new tokens to mint
    function bridgeMint(address to, uint256 value) external;

    /// @notice Burn tokens when bridging
    /// @dev This function is only used for bridging to burn tokens on one end
    /// @param from Address to burn tokens from
    /// @param value Number of tokens to burn
    function bridgeBurn(address from, uint256 value) external;

    /// @notice View all rewards claimable by a staker
    /// @param staker Address of the staker
    /// @return Number of $CELL claimable by the staker
    function getAllRewards(address staker) external view returns (uint256);

    /// @notice View rewards claimable for a specific SheetFighterToken
    /// @param tokenId Id of the SheetFightToken
    /// @return Number of $CELL claimable by the staker for this Sheet
    function getRewardsByTokenId(uint256 tokenId) external view returns (uint256);

    /// @notice Get all the token Ids staked by a staker
    /// @param staker Address of the staker
    /// @return Array of tokens staked
    function getTokensStaked(address staker) external view returns (uint256[] memory);

    /// @notice Burn cell on behalf of an account
    /// @param account Address for account
    /// @param amount Amount to burn
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPortal {
    function sendMessage(bytes calldata message_) external;
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
    function receiveMessage(bytes memory data) external;
}