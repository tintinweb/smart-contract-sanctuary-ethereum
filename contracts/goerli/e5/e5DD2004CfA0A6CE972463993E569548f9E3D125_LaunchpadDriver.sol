// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IDataToBytes.sol";

interface ILaunchpadLogic {
    function accessCheck(bool _approved, address user, address _admin, address _projectOwner, bytes[] memory data) external view returns(bool);
}

contract LaunchpadDriver is Ownable {

    
    mapping(uint => projectInfo) public projectsList; //id => projectInfo
    mapping(address => bool) public allowedInvestTokens;

    uint[] public waitingList;
    uint public id = 1;
    uint public applicationFee = 1 ether; //no return
    uint public fee = 1000; //100 = 1% from each invest

    address launchpadLogic;
    address dataToBytes;
    address public feeCollector;

    bool isWorking = true;

    struct projectInfo {
        address projectAddress;
        bool approved;
    }

    constructor(address _feeCollector, address _logic, address _dataToBytes) {
        launchpadLogic = _logic;
        dataToBytes = _dataToBytes;
        feeCollector = _feeCollector;
    }

    function ApplyToCreateProject(uint minLock, string memory name, string memory ticker, bytes[] memory data) external payable {
        require(isWorking);
        require(msg.value >= applicationFee);
        projectsList[id].projectAddress = address(new LaunchpadProjectInfo(feeCollector, dataToBytes, minLock, id, name, ticker, launchpadLogic, fee, msg.sender, data));
        waitingList.push(id);
        id++;
        (bool success,) = feeCollector.call{value : address(this).balance}("");
        require(success);
    }

    function callFunctions(address _projectAddress, bytes[] memory data) public onlyOwner {
        LaunchpadProjectInfo(_projectAddress).callFunctions(data);
    } 

    function approveProject(uint _id, bytes[] memory data) external onlyOwner {
        callFunctions(projectsList[_id].projectAddress, data);
        _deleteIndex(_id);
    }
 
    function changeFee(uint _newFee) public onlyOwner {
        fee = _newFee;
    }

    function stopAndStart(bool _position) public onlyOwner {
        isWorking = _position;
    }

    function setInvestToken(address _tokenAddr, bool _position) public onlyOwner {
        allowedInvestTokens[_tokenAddr] = _position;
    }

    function setApplicationFee(uint _newFee) public onlyOwner {
        applicationFee = _newFee;
    }

    function _deleteIndex(uint _id) private {
        uint _index;
        for(uint i; i < waitingList.length;) {
            if(waitingList[i] == _id){
                _index = id;
                break;
            }
            i++;
        }
        for (uint i = _index; i < waitingList.length - 1; i++) {
            waitingList[i] = waitingList[i+1];
        }
        waitingList.pop();
    }
}

contract LaunchpadProjectInfo {

    //@Dev Fee, rewardPercentage: 100 = 1% 

    string public projectName;
    string public shortDescription;
    string public fullDescription;
    string public website;
    string public youtubeVideo;
    string public country;
    string public headerLink;
    string public previewLink;
    string public whitepaperLink;
    string public roadmapLink;
    string public businessPlanLink;
    string public additionalDocsLink;
    string[] public owners;
    string[] public highlights;

    string[] public socialMediaName;
    string[] public socialMediaLogin;
    string[] public socialMediaPersonName;
    string[] public socialMediaPersonLogin;
    string[] public socialMediaPersonType;
    string[] public personAvatarLink;
    
    address public projectOwner;
    address public admin;
    address public investToken;
    address public projectToken;
    address public launchpadLogic;
    address public feeCollector;
    address dataToBytes;

    uint public PROJECT_ID;
    uint public stage;
    uint public softCap;
    uint public hardCap;

    uint public collectedFees;
    uint public collectedFundTOTAL;
    uint public fee = 500;

    uint public investorsReward;
    uint public distributedFunds;
    uint public rewardPercentage;

    uint public startFunding;
    uint public endFunding;
    uint public category;
    uint public minimumLock;
    uint public currentBalance;
    
    bool public canceled;
    bool public verified;
    bool public approved;
    bool paidFees;


    mapping(uint => RoadMap) public roadmap; 
    mapping(address => uint) public rawInvested;
    
    struct RoadMap {
        string description;
        uint funds;
        bool ableToClaim;
    }

    bytes4[] _adminSelectors = [
        bytes4(0xb4e830f1), //ApproveProject
        bytes4(0x13c35f34), //changeVerification
        bytes4(0xca3555b8), //AllowToClaim
        bytes4(0x1adff0ee), //cancelProject
        bytes4(0x6a1db1bf)  //changeFee
    ];

    bytes4[] _userSelectors = [
        bytes4(0x2afcf480), //invest
        bytes4(0x4e71d92d), //claim
        bytes4(0x6d0c40fd), //getCollectedFunds
        bytes4(0x8a160b54), //DistributeProfit
        bytes4(0x590e1ae3)  //refund
    ];

    constructor(address _feeCollector, address _dataToBytes, uint minLock, uint id, string memory name, string memory ticker, address _logic, uint _fee, address _owner, bytes[] memory data){
        launchpadLogic = _logic;
        PROJECT_ID = id;
        fee = _fee;
        admin = msg.sender;
        projectOwner = _owner;
        minimumLock = minLock;
        dataToBytes = _dataToBytes;
        feeCollector = _feeCollector;
        for (uint i = 0; i < data.length; i++) {
            (bool success,) = launchpadLogic.delegatecall(data[i]);
            require(success);
        }
        projectToken = address(new ProjectToken(name, ticker));
    }

    function callFunctions(bytes[] memory data) external accessCheck(data){
        for (uint i = 0; i < data.length; i++) {
            (bool success,) = launchpadLogic.delegatecall(data[i]);
            require(success, "Call Functions : Failed");
        }
    }

    modifier accessCheck(bytes[] memory data) {
        bytes memory _data = IDataToBytes(dataToBytes).accessCheck(data);
        (bool success, ) = launchpadLogic.delegatecall(_data);
        require(success, "AccessCheck : Failed");
        _;
    }

}


contract ProjectToken is ERC20, Ownable {
    constructor(string memory name, string memory ticker) ERC20(name, ticker) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
pragma solidity ^0.8.17;

interface IDataToBytes {
        
    function changeCompanyName(string memory _newName) external pure returns(bytes memory);

    function changeShortDescription(string memory _newShortDescription) external pure returns(bytes memory);

    function changeFullDescriprion(string memory _newfullDescription) external pure returns(bytes memory);

    function changeWebsite(string memory _newWebsite) external pure returns(bytes memory);

    function changeVideo(string memory _newVideo) external pure returns(bytes memory);

    function changeCountry(string memory _newCountry) external pure returns(bytes memory);

    function changeOwners(string[] memory _owners) external pure returns(bytes memory);

    function changeProjectOwner(address _owner) external pure returns(bytes memory);

    function changeToken(address _token) external pure returns(bytes memory);

    function changeCategory(uint _category) external pure returns(bytes memory);

    function changeSoftCap(uint _soft) external pure returns(bytes memory);

    function changeHardCap(uint _hard) external pure returns(bytes memory);

    function changeStart(uint _newStart) external pure returns(bytes memory);

    function changeEnd(uint _newEnd) external pure returns(bytes memory);

    function changeHighlights(string[] memory _newHighlights) external pure returns(bytes memory);

    function changeReward(uint _newReward) external pure returns(bytes memory);
    
    function changeSocialMediaName(string[] memory _name) external pure returns(bytes memory);

    function changeSocialMediaLogin(string[] memory _login) external  pure returns(bytes memory);

    function changeSocialMediaPersonName(string[] memory _name) external pure returns(bytes memory);

    function changeSocialMediaPersonLogin(string[] memory _login) external  pure returns(bytes memory);
    
    function changeRoadmapDescription(string memory _description, uint _stageToChange) external pure returns(bytes memory);

    function approveProject() external pure returns(bytes memory);

    function changeVerification(bool _verified) external pure returns(bytes memory);

    function changeFee(uint _newFee) external pure returns(bytes memory);

    function setApplicationFee(uint _newFee) external pure returns(bytes memory);

    function changeRoadmapFunds(uint _newFunds, uint _stageToChange) external pure returns(bytes memory);

    function changeToSecurityFund(uint _newAmount) external pure returns(bytes memory);

    function allowToClaim(bool _newPosition) external pure returns(bytes memory);

    function cancelProject() external  pure returns(bytes memory);

    function refund() external pure returns(bytes memory);

    function accessCheck(bytes[] memory data) external pure returns(bytes memory);
    
    function distributeProfit() external pure returns(bytes memory);

    function claim() external pure returns(bytes memory);

    function changeMinlock(uint _newLock) external pure returns(bytes memory);

    function changeSocialMediaPersonType(string[] memory _type) external pure returns(bytes memory);

    function changePersonAvatarLink(string[] memory _link) external pure returns(bytes memory);

    function changeHeaderLink(string memory _link) external pure returns(bytes memory);

    function changePreviewLink(string memory _link) external pure returns(bytes memory);

    function changeWhitepaperLink(string memory _link) external pure returns(bytes memory);

    function changeRoadmapLink(string memory _link) external pure returns(bytes memory);

    function changeBusinessPlanLink(string memory _link) external pure returns(bytes memory);

    function changeAdditionalDocsLink(string memory _link) external pure returns(bytes memory);
}