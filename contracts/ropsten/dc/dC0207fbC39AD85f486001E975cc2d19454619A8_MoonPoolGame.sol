/**
 *Submitted for verification at Etherscan.io on 2022-01-29
*/

pragma solidity 0.8.9;

/**
 * @title MoonPoolGame
 * 
 * Smart contract for staking ERC20 tokens, enabling an organization to track externally the deposits and withdrawals of his users via Events.
 * The user needs to approve this smart contract to move the tokens to the smart contract balance. Once the user make the deposit,
 * the user can withdraw his ERC20 anytime.
 *
 * For example, an organization can reward the user addresses that lock the tokens in this contract for a determinated amount of time,
 * tracking the events of deposit and withdrawal from a determinated user, to calculate a specific reward.
 */

 abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

 interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }
}

contract MoonPoolGame is Ownable {

  // Account balances
  mapping (address => uint) public balances; 
  
  // ERC20 Token Contract address
  address tokenAddress = 0x7E5f01710B2D1637853d135BF84037e928944952;
  
  // ERC20 Token Instance
  IERC20 tokenInstance;

  event Deposit(address account, uint amount, uint blockNumber);
  event Withdrawal(address account, uint amount, uint blockNumber);
    
  function setToken(address contractAddress) public onlyOwner {
    tokenAddress = contractAddress;
    tokenInstance = IERC20(tokenAddress);
  }

  function withdrawERC20() public {
    require(tokenAddress != address(0), "ERC20 token contract is not set. Please contact with the smart contract owner.");
    uint256 allBalance = balances[msg.sender];
    require(allBalance > 0,  "No balance left.");
    balances[msg.sender] = 0;
    require(tokenInstance.transfer(msg.sender, allBalance), "Error while making ERC20 transfer");
    emit Withdrawal(msg.sender, allBalance, block.number);
  }

  function depositERC20(address account, uint256 amount) public {
    require(tokenAddress != address(0), "ERC20 token contract is not set. Please contact with the smart contract owner.");
    require(tokenInstance.allowance(account, address(this)) == amount, "Owner did not allow this smart contract to transfer.");
    tokenInstance.transferFrom(account, address(this), amount);
    balances[account] += amount;
    emit Deposit(account, amount, block.number);
  }
}