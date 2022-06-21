/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// File: contracts/interfaces/ILiquidity.sol


pragma solidity ^0.8.4;

interface ILiquidity {
    function totalLiquidity() external view returns (uint256);

    function initSwap(uint256 _amount, address payable _receiver)
        external
        view
        returns (bool);

    function completeSwap(uint256 _amount, address payable _receiver)
        external
        view
        returns (bool);

    function unSwap(uint256 _amount, address payable _receiver)
        external
        view
        returns (bool);

    function dco2InUSDC() external pure returns (uint256);
}
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Params.sol



pragma solidity ^0.8.4;



contract DeCarbParams is Ownable {
    address public treasuryAdd;
    ILiquidity public priceOrc;

    mapping(uint256 => mapping(string => uint256)) public getVintagePrice; //vitage=>projectId=>price
    mapping(uint256 => mapping(string => bool)) public isProjectId;

    constructor() {
        transferOwnership(msg.sender);
    }

    function setProjectId(uint256 _vintage, string memory _projectId)
        external
        onlyOwner
    {
        isProjectId[_vintage][_projectId] = true;
    }

    function deleteProjectId(uint256 _vintage, string memory _projectId)
        external
        onlyOwner
    {
        isProjectId[_vintage][_projectId] = false;
    }

    function setVintagePrice(
        uint256 _vintage,
        string memory _projectId,
        uint256 _price
    ) external onlyOwner {
        require(isProjectId[_vintage][_projectId], "ID does not exist");
        getVintagePrice[_vintage][_projectId] = _price;
    }

    function setTreasuryAddress(address _treasuryAdd) external onlyOwner {
        require(_treasuryAdd != address(0), "treasury address must not be 0x0");
        treasuryAdd = _treasuryAdd;
    }

    function setDco2USDC(address _orclAdd) external onlyOwner {
        priceOrc = ILiquidity(_orclAdd);
    }

    function getDco2USDC() external view returns (uint256) {
        return priceOrc.dco2InUSDC();
    }

    function isProjectIdApproved(uint256 _vintage, string memory _projectId)
        public
        view
        returns (bool)
    {
        return isProjectId[_vintage][_projectId];
    }

    function getVintPrice(uint256 _vintage, string memory _projectId)
        external
        view
        returns (uint256)
    {
        return getVintagePrice[_vintage][_projectId];
    }
}