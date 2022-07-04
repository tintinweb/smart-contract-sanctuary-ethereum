/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract HatiSacrifice is Ownable
{
    uint public hatiWarchestDeposited;
    uint public nftHoldersDeposited;
    mapping(address => mapping(address => uint)) public baseDepositedByLP; /* LP[base][amount] */
    address public hatiWarchestVaultAddress = 0x000000000000000000000000000000000000dEaD;
    address public nftHoldersVaultAddress = 0x000000000000000000000000000000000000dEaD;
    address public lpProvidersVaultAddress = 0x000000000000000000000000000000000000dEaD;

    // Admin Functions

    function setHatiWarchestVaultAddress(address _hatiWarchestVaultAddress) external onlyOwner{
        hatiWarchestVaultAddress = _hatiWarchestVaultAddress;
    }

    function setNFTHoldersVaultAddress(address _nftHoldersVaultAddress) external onlyOwner {
        nftHoldersVaultAddress = _nftHoldersVaultAddress;
    }

    function setLPProvidersVaultAddress(address _lpProvidersVaultAddress) external onlyOwner {
        lpProvidersVaultAddress = _lpProvidersVaultAddress;
    }

    function withdrawHatiWarchest(address destination, address token, uint amount) public onlyOwner {
        hatiWarchestDeposited -= amount;
        IERC20(token).transfer(destination, amount);
    }

    function withdrawNFTHolders(address destination, address token, uint amount) public onlyOwner {
        nftHoldersDeposited -= amount;
        IERC20(token).transfer(destination, amount);
    }

    function withdrawLPProviders(address destination, address lpAddress, address token, uint amount) public onlyOwner {
        baseDepositedByLP[lpAddress][token] -= amount;
        IERC20(token).transfer(destination, amount);
    }

    function genericWithdraw(address destination, address token, uint amount) public onlyOwner {
        IERC20(token).transfer(destination, amount);
    }

    // View functions

    function getHatiWarchestVaultAddress() public view returns(address)
    {
        return hatiWarchestVaultAddress;
    }

    function getNFTHoldersVaultAddress() public view returns(address)
    {
        return nftHoldersVaultAddress;
    }

    function getLPProvidersVaultAddress() public view returns(address)
    {
        return lpProvidersVaultAddress;
    }

    // Pair Functions
    function depositToken(address lpAddress, address addressBaseToken, uint amount) public
    {
        uint hatiWarchestAmount = amount/3;
        uint nftHoldersAmount = amount/3;
        baseDepositedByLP[lpAddress][addressBaseToken] += amount - hatiWarchestAmount - nftHoldersAmount;
        IERC20(addressBaseToken).transferFrom(msg.sender, address(this), amount);
    }
}