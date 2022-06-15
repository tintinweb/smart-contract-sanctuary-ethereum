// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "GenesisSale.sol";

contract GenesisSaleDebug is GenesisSale {

    constructor(
        IRoachNFT _roachContract,
        uint stage1startTime,
        uint stage1durationSeconds,
        uint totalTokensOnSale)
        GenesisSale(_roachContract, stage1startTime, stage1durationSeconds, totalTokensOnSale)
    {
    }

    function mintStage1noSig(
        uint desiredCount,
        uint limitForAccount,
        uint price,
        uint8 traitBonus,
        string calldata syndicate
    )
        external payable
    {
        _mint(msg.sender, desiredCount, limitForAccount, price, traitBonus, syndicate);
    }

    function setStage0(uint duration) external onlyOperator {
        SALE_START = block.timestamp + duration;
    }

    function setStage1(uint duration) external onlyOperator {
        SALE_START = block.timestamp;
        SALE_DURATION = duration;
    }

    function setStage2() external onlyOperator {
        SALE_START = block.timestamp - SALE_DURATION;
    }

    function setStage3() external onlyOperator {
        SALE_START = block.timestamp - SALE_DURATION;
    }

}

// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
/*
______                 _      ______           _               _____ _       _
| ___ \               | |     | ___ \         (_)             /  __ \ |     | |
| |_/ /___   __ _  ___| |__   | |_/ /__ _  ___ _ _ __   __ _  | /  \/ |_   _| |__
|    // _ \ / _` |/ __| '_ \  |    // _` |/ __| | '_ \ / _` | | |   | | | | | '_ \
| |\ \ (_) | (_| | (__| | | | | |\ \ (_| | (__| | | | | (_| | | \__/\ | |_| | |_) |
\_| \_\___/ \__,_|\___|_| |_| \_| \_\__,_|\___|_|_| |_|\__, |  \____/_|\__,_|_.__/
                                                        __/ |
                                                       |___/
.................................,,:::,...........
..............................,:;;;:::;;;,........
...............,,,,,.........:;;,......,;+:.......
.............:::,,,::,.....,+;,..........:*;......
...........,;:.......,:,..,+:.............:*:.....
..........:;,..........:,.+:...............*+.....
.........,+,..........,,:;+,,,.............;*,....
.........+:.......,:+?SS####SS%*;,.........;*:....
........:+.....,;?S##############S?:.......;*,....
........;+....;?###############%??##+......+*,....
........:+...,%SS?;?#########@@S?++S#:....,+;.....
........,+:..,%S%*,*#####SSSSSS%*;,%S,............
.........;;,..;SS%S#####SSSS%%%?+:*%;.............
..........,....:%########SSS%%?*?%?,..............
.............,,,.+S##@#?+;;*%%SS%;................
.........,,.,+++;:+%##?+*+:,?##S+;:,..............
....,,;+*SS*??***++?S#S?*+:,%S%%%%%?+:,......,....
,:;**???*?#@##S?***++*%%*;,:%%%%**?%%?;,,.,;?%?%??
????*+;:,,*####S%%?*+;:;;,,+#S%%%?*?%??+;*%S?*%SSS
*+;:,....,%@S####SS%?*+:::*[email protected]#%%%%????%%S%*;::,,,:
[email protected]@S%S####S#@%?%%SS#@SS%%%%SS%*++;,......
........,%@@S%%S#@##@#%%%%%%[email protected]##SSS%*+*?%?;,......
........:#@@%%%%%[email protected]##%%%%%%%#@##?++**%%S%+:......
[email protected]@#%SS%%%SSS?S%%%%%%[email protected]?????%?S%*;,.....
[email protected]@@%%%%%%%%%%%%%%%%%%%%%%??**?%#%%;,.....
*/
pragma solidity ^0.8.10;

import "Operators.sol";
import "IRoachNFT.sol";

/// @title Genesis collection sale contract
/// @author Shadow Syndicate / Andrey Pelipenko ([email protected])
/// @dev Distribute 10k tokens with arbitrary price to whitelisted accounts with limit
contract GenesisSale is Operators {

    uint public TOTAL_TOKENS_ON_SALE = 10_000;
    uint public SALE_START;
    uint public SALE_DURATION;
    address public signerAddress;
    IRoachNFT public roachContract;

    event Purchase(address indexed account, uint count, uint traitBonus, string syndicate, uint ethValue);

    constructor(
        IRoachNFT _roachContract,
        uint stage1startTime,
        uint stage1durationSeconds,
        uint totalTokensOnSale)
    {
        roachContract = _roachContract;
        SALE_START = stage1startTime;
        SALE_DURATION = stage1durationSeconds;
        TOTAL_TOKENS_ON_SALE = totalTokensOnSale;
        signerAddress = msg.sender;
    }

    /// @notice Returns current sale status
    /// @param account Selected buyer address
    /// @return stage One of number 0..3: 0 - presale not started. 1 - Presale. 2 - Public sale. 3 - sale is over.
    /// @return leftToMint Left roaches to mint in total
    /// @return nextStageTimestamp UNIX time of current stage finish and next stage start. Always 0 for for stages 2 and 3.
    /// @return price One roach price in ETH.
    /// @return allowedToMint For stage 2 - max count for one tx.
    function getSaleStatus(address account, uint limitForAccount) external view returns (
        uint stage,
        int leftToMint,
        uint nextStageTimestamp,
        uint price,
        int allowedToMint)
    {
        stage = getSaleStage();

        price = 0;
        nextStageTimestamp =
            stage == 0 ? SALE_START :
            stage == 1 ? SALE_START + SALE_DURATION :
            0;
        leftToMint = int(TOTAL_TOKENS_ON_SALE) - int(totalMinted());
        allowedToMint =
            stage == 1 ? (int)(getAllowedToBuyForAccount(account, limitForAccount)) :
            int(0);
    }

    /// @notice Total number of minted tokens
    function totalMinted() public view returns (uint256) {
        return roachContract.lastRoachId();
    }

    function isPresaleActive() public view returns (bool) {
        return SALE_START <= block.timestamp
            && block.timestamp < SALE_START + SALE_DURATION
            && totalMinted() < TOTAL_TOKENS_ON_SALE;
    }

    /// @return stage One of number 0..3: 0 - presale not started. 1 - Sale. 3 - sale is over.
    function getSaleStage() public view returns (uint) {
        return isPresaleActive() ? 1 :
            block.timestamp < SALE_START ? 0 :
            2;
    }

    /// @notice Takes payment and mints new roaches on Presale Sale.
    /// @dev    Function checks signature, generated by backend for buyer account according to whitelist limitations.
    ///         Can be called twice if total minted token count doesn't exceed limitForAccount.
    /// @param desiredCount The number of roach to mint
    /// @param limitForAccount Original buy limit from whitelist
    /// @param price One roach price from whitelist
    /// @param traitBonus Trait bonus from whitelist (12 means 12% bonus)
    /// @param syndicate (Optional) Syndicate name, that player wants join to. Selected syndicate will receive a bonus.
    /// @param sigV sigR sigS Signature that can be generated only by secret key, stored on game backend
    function mint(
        uint desiredCount,
        uint limitForAccount,
        uint price,
        uint8 traitBonus,
        string calldata syndicate,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS
    )
        external payable
    {
        require(isValidSignature(msg.sender, limitForAccount, price, traitBonus, sigV, sigR, sigS), "Wrong signature");
        _mint(msg.sender, desiredCount, limitForAccount, price, traitBonus, syndicate);
    }

    /// @notice returns left allowed tokens for minting on Presale if purchase is preformed using several transaction
    function getAllowedToBuyForAccount(address account, uint limitForAccount) public view returns (uint) {
        uint256 numberMinted = roachContract.getNumberMinted(account);
        return limitForAccount > numberMinted
            ? limitForAccount - numberMinted
            : 0;
    }

    function _mint(
        address account,
        uint desiredCount,
        uint limitForAccount,
        uint price,
        uint8 traitBonus,
        string calldata syndicate)
        internal
    {
        uint stage = getSaleStage();
        require(stage == 1, "Sale not active");
        uint leftToMint = getAllowedToBuyForAccount(account, limitForAccount);
        require(desiredCount <= leftToMint, 'Account limit reached');

        _buy(account, desiredCount, price, syndicate, traitBonus);
    }

    function _buy(address account, uint count, uint price, string calldata syndicate, uint8 traitBonus) internal {
        require(count > 0, 'Min count is 1');
        uint soldCount = totalMinted();
        if (soldCount + count > TOTAL_TOKENS_ON_SALE) {
            count = TOTAL_TOKENS_ON_SALE - soldCount; // allow to buy left tokens
        }
        uint needMoney = price * count;
        emit Purchase(account, count, traitBonus, syndicate, msg.value);
        _mintRaw(account, count, traitBonus, syndicate);
        _acceptMoney(needMoney);
    }

    function _acceptMoney(uint needMoney) internal {
        require(msg.value >= needMoney, "Insufficient money");
    }

    function _mintRaw(address to, uint count, uint8 traitBonus, string calldata syndicate) internal {
        roachContract.mintGen0(to, count, traitBonus, syndicate);
    }

    /// Signatures

    /// @notice Internal function used in signature checking
    function hashArguments(address account, uint limitForAccount, uint price, uint8 traitBonus)
        public pure returns (bytes32 msgHash)
    {
        msgHash = keccak256(abi.encode(account, limitForAccount, price, traitBonus));
    }

    /// @notice Internal function used in signature checking
    function getSigner(
        address account, uint limitForAccount, uint price, uint8 traitBonus,
        uint8 sigV, bytes32 sigR, bytes32 sigS
    )
        public pure returns (address)
    {
        bytes32 msgHash = hashArguments(account, limitForAccount, price, traitBonus);
        return ecrecover(msgHash, sigV, sigR, sigS);
    }

    /// @notice Internal function used in signature checking
    function isValidSignature(
        address account, uint limitForAccount, uint price, uint8 traitBonus,
        uint8 sigV, bytes32 sigR, bytes32 sigS
    )
        public
        view
        returns (bool)
    {
        return getSigner(account, limitForAccount, price, traitBonus, sigV, sigR, sigS) == signerAddress;
    }

    /// @notice Mints new NFT with selected parameters
    /// @dev There is a guarantee that there will no more than 10k genesis roaches
    function mintOperator(address to, uint count, uint8 traitBonus, string calldata syndicate) external onlyOperator {
        uint soldCount = totalMinted();
        require(soldCount + count <= TOTAL_TOKENS_ON_SALE, "Sale is over");
        _mintRaw(to, count, traitBonus, syndicate);
    }

    /// @notice Changes secret key that is used for signature generation
    function setSigner(address newSigner) external onlyOwner {
        signerAddress = newSigner;
    }

}

// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "IERC20.sol";
import "Ownable.sol";

/// @title Helper contract for contract maintainance
/// @author Shadow Syndicate / Andrey Pelipenko ([email protected])
contract Operators is Ownable {
    mapping (address=>bool) operatorAddress;

    modifier onlyOperator() {
        require(isOperator(msg.sender), "Access denied");
        _;
    }

    function isOwner(address _addr) public view returns (bool) {
        return owner() == _addr;
    }

    function isOperator(address _addr) public view returns (bool) {
        return operatorAddress[_addr] || isOwner(_addr);
    }

    function _addOperator(address _newOperator) internal {
        operatorAddress[_newOperator] = true;
    }

    function addOperator(address _newOperator) external onlyOwner {
        require(_newOperator != address(0), "New operator is empty");
        _addOperator(_newOperator);
    }

    function removeOperator(address _oldOperator) external onlyOwner {
        delete(operatorAddress[_oldOperator]);
    }

    /**
     * @dev Owner can claim any tokens that are transferred
     * to this contract address
     */
    function withdrawERC20(IERC20 _tokenContract, address _admin) external onlyOwner {
        uint256 balance = _tokenContract.balanceOf(address(this));
        _tokenContract.transfer(_admin, balance);
    }

    function withdrawEther() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.10;

/// @title Roach Racing Club NFT registry interface
interface IRoachNFT {

    /// @notice Mints new token with autoincremented index and stores traitBonus/syndicate for reveal
    function mintGen0(address to, uint count, uint8 traitBonus, string calldata syndicate) external;

    /// @notice lastRoachId doesn't equap totalSupply because some token will be burned
    ///         in using Run or Die mechanic
    function lastRoachId() external view returns (uint);

    /// @notice Total number of minted tokens for account
    function getNumberMinted(address account) external view returns (uint64);

    function revealOperator(uint tokenId, bytes calldata genome) external;

    function ownerOf(uint256 tokenId) external view returns (address);
}