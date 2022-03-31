/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Strings.sol

pragma solidity ^0.8.7;
pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
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

abstract contract IJungeTycoon {
    uint256 public cost;
    function totalSupply() virtual external view returns (uint256);
    function mint(uint256 _mintAmount) virtual public payable;
    function transferFrom(address from, address to, uint256 tokenId) virtual external;
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MintReward is Ownable, IERC721Receiver {
    IJungeTycoon public jungeTycoon;
    IERC20 public toopi;
    uint256 public amountPerMint;

    event WithdrawnToken(address owner, uint256 amount);

    constructor(address _jungeTycoon, address _toopi, uint256 _amountPerMint) {
        jungeTycoon = IJungeTycoon(_jungeTycoon);
        toopi = IERC20(_toopi);
        amountPerMint = _amountPerMint;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setERC721Address(address _jungeTycoon) external onlyOwner {
        jungeTycoon = IJungeTycoon(_jungeTycoon);
    }

    function setRewardTokenAddress(address _toopi) external onlyOwner {
        toopi = IERC20(_toopi);
    }

    function setAmountPerMint(uint256 _amountPerMint) external onlyOwner {
        amountPerMint = _amountPerMint;
    }


    function mint(uint256 amount) external {
        require(amount > 0, "You need to mint with at least some tokens");
        uint256 allowance = toopi.allowance(msg.sender, address(this));
        require(allowance >= amount * amountPerMint, "Check the token allowance");
        toopi.transferFrom(msg.sender, address(this), amount * amountPerMint);

        uint256 cost = jungeTycoon.cost();
        uint256 accountBalance = address(this).balance;
        require(accountBalance > amount * cost, "Not enough eth balance.");

        jungeTycoon.mint{value: amount * cost}(amount);
        
        uint256 totalSupply = jungeTycoon.totalSupply();
        for (uint256 i = 0; i < amount; i ++) {
            jungeTycoon.transferFrom(address(this), msg.sender, totalSupply - i);
        }

    }

    function depositEth() public payable onlyOwner {   
    }
    
    function withdrawEth() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function withdrawToken() public onlyOwner {
        uint256 toopiBalance = toopi.balanceOf(address(this));
        require(toopiBalance > 0, "Amount of Toopi is zero.");
        toopi.transfer(msg.sender, toopiBalance);
        emit WithdrawnToken(msg.sender, toopiBalance);       
    }
    
}