/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: distributor1.sol

//SPDX-License-Identifier: MIT



pragma solidity ^0.8.0;





contract TokenDistributor1 is Ownable{



  address public KaleToken;

  address public wallet1;

  address public wallet2;

  address public wallet3;

  address public wallet4;

  address public wallet5;

  address public wallet6;

  uint256[6] public deadline;

  uint256[6] public lastClaimTime;

  uint256[6] public remainAmounts;

  uint256[6] public DistributorAmount = [4_500_000_000*10**18, 2_000_000_000*10**18, 2_000_000_000*10**18, 700_000_000*10**18, 500_000_000*10**18, 300_000_000*10**18];

  uint256[6] public distributeAmountsPerMonth = [75_000_000*10**18, 33_333_333*10**18, 33_333_333*10**18, 29_166_666*10**18, 500_000_000*10**18, 25_000_000*10**18];

  uint256 public constant totalDistributeAmounts = 10_000_000_000 * 10**18;

  constructor(address _wallet1,address _wallet2,address _wallet3,address _wallet4,address _wallet5,address _wallet6) {

    wallet1 = _wallet1;

    wallet2 = _wallet2;

    wallet3 = _wallet3;

    wallet4 = _wallet4;

    wallet5 = _wallet5;

    wallet6 = _wallet6;

  }

  

  function setDistributorAddress1(address _walletAddress) public onlyOwner{

    require(wallet1 !=_walletAddress, "wallet1 must not be equals address that setting now.");

    wallet1 = _walletAddress;

  }



  function setDistributorAddress2(address _walletAddress) public onlyOwner{

    require(wallet2 !=_walletAddress, "wallet2 must not be equals address that setting now.");

    wallet2 = _walletAddress;

  }



  function setDistributorAddress3(address _walletAddress) public onlyOwner{

    require(wallet3 !=_walletAddress, "wallet3 must not be equals address that setting now.");

    wallet3 = _walletAddress;

  }



  function setDistributorAddress4(address _walletAddress) public onlyOwner{

    require(wallet4 !=_walletAddress, "wallet4 must not be equals address that setting now.");

    wallet4 = _walletAddress;

  }



  function setDistributorAddress5(address _walletAddress) public onlyOwner{

    require(wallet5 !=_walletAddress, "wallet5 must not be equals address that setting now.");

    wallet5 = _walletAddress;

  }



  function setDistributorAddress6(address _walletAddress) public onlyOwner{

    require(wallet6 !=_walletAddress, "wallet6 must not be equals address that setting now.");

    wallet6 = _walletAddress;

  }





  function setTokenContract(address _KaleToken) public onlyOwner {

      KaleToken = _KaleToken;

      deadline[0] = block.timestamp + 5 *365 days;

      deadline[1] = block.timestamp + 5 *365 days;

      deadline[2] = block.timestamp + 5 *365 days;

      deadline[3] = block.timestamp + 2 *365 days;

      deadline[4] = block.timestamp;

      deadline[5] = block.timestamp + 1 *365 days;

      lastClaimTime[0] = block.timestamp;

      lastClaimTime[1] = block.timestamp;

      lastClaimTime[2] = block.timestamp;

      lastClaimTime[3] = block.timestamp;

      lastClaimTime[5] = block.timestamp;

      remainAmounts[0] = DistributorAmount[0] - distributeAmountsPerMonth[0];

      remainAmounts[1] = DistributorAmount[1] - distributeAmountsPerMonth[1];

      remainAmounts[2] = DistributorAmount[2] - distributeAmountsPerMonth[2];

      remainAmounts[3] = DistributorAmount[3] - distributeAmountsPerMonth[3];

      remainAmounts[5] = DistributorAmount[5] - distributeAmountsPerMonth[5];

      require(IERC20(KaleToken).balanceOf(address(this)) == totalDistributeAmounts, "balance of distributor contract was not provided yet.");

      require(wallet1 !=address(0), "wallet1 must not be zero.");

      require(wallet2 !=address(0), "wallet2 must not be zero.");

      require(wallet3 !=address(0), "wallet3 must not be zero.");

      require(wallet4 !=address(0), "wallet4 must not be zero.");

      require(wallet5 !=address(0), "wallet5 must not be zero.");

      require(wallet6 !=address(0), "wallet6 must not be zero.");

      IERC20(KaleToken).transfer(wallet1, distributeAmountsPerMonth[0]);

      IERC20(KaleToken).transfer(wallet2, distributeAmountsPerMonth[1]);

      IERC20(KaleToken).transfer(wallet3, distributeAmountsPerMonth[2]);

      IERC20(KaleToken).transfer(wallet4, distributeAmountsPerMonth[3]);

      IERC20(_KaleToken).transfer(wallet5, distributeAmountsPerMonth[4]); 

      IERC20(KaleToken).transfer(wallet6, distributeAmountsPerMonth[5]);     

  }   

 

  function distributeToWallet1() public onlyOwner{

    //require(deadline[0] >= block.timestamp , "over time");

    require(KaleToken != address(0) , "didn't set Token address");

    require(lastClaimTime[0] + 30 days <= block.timestamp , "not claim time");

    

    require(remainAmounts[0] > 0, "distribution was done.");

    require(wallet1 !=address(0), "wallet1 must not be zero.");

    uint256 months = (block.timestamp - lastClaimTime[0]) / 30 days;

    uint256 distributeAmounts = months * distributeAmountsPerMonth[0];

    if(block.timestamp >= deadline[0]-55 days){

      distributeAmounts = remainAmounts[0];

      remainAmounts[0] = 0;

    }

    else{

      remainAmounts[0] -= distributeAmounts;

    }

    require(IERC20(KaleToken).balanceOf(address(this)) >= distributeAmounts, "balance of distributor contract is smaller than distributionAmounts.");

    IERC20(KaleToken).transfer(wallet1, distributeAmounts);    

    lastClaimTime[0] += 30 days * months;

  }  



  function distributeToWallet2() public onlyOwner{

    //require(deadline[1] >= block.timestamp , "over time");  

    require(KaleToken != address(0) , "didn't set Token address"); 

    require(lastClaimTime[1] + 30 days <= block.timestamp , "not claim time");

    

    require(remainAmounts[1] > 0, "distribution was done.");

    require(wallet2 !=address(0), "wallet2 must not be zero.");

    uint256 months = (block.timestamp - lastClaimTime[1]) / 30 days;

    uint256 distributeAmounts = months * distributeAmountsPerMonth[1];



    if(block.timestamp >= deadline[1]-55 days){

      distributeAmounts = remainAmounts[1];

      remainAmounts[1] = 0;

    }

    else{

      remainAmounts[1] -= distributeAmounts;

    }

    require(IERC20(KaleToken).balanceOf(address(this)) >= distributeAmounts, "balance of distributor contract is smaller than distributionAmounts.");

    IERC20(KaleToken).transfer(wallet2, distributeAmounts);    

    lastClaimTime[1] += 30 days * months;

  }



  function distributeToWallet3() public onlyOwner{

    //require(deadline[2] >= block.timestamp , "over time");   

    require(KaleToken != address(0) , "didn't set Token address");

    require(lastClaimTime[2] + 30 days <= block.timestamp , "not claim time");

    

    require(remainAmounts[2] > 0, "distribution was done.");

    require(wallet3 !=address(0), "wallet3 must not be zero.");

    uint256 months = (block.timestamp - lastClaimTime[2]) / 30 days;

    uint256 distributeAmounts = months * distributeAmountsPerMonth[2];



    if(block.timestamp >= deadline[2]-40 days){

      distributeAmounts = remainAmounts[2];

      remainAmounts[2] = 0;

    }

    else{

      remainAmounts[2] -= distributeAmounts;

    }

    require(IERC20(KaleToken).balanceOf(address(this)) >= distributeAmounts, "balance of distributor contract is smaller than distributionAmounts.");

    IERC20(KaleToken).transfer(wallet3, distributeAmounts);    

    lastClaimTime[2] += 30 days * months;    

  }



  function distributeToWallet4() public onlyOwner{    

    //require(deadline[3] >= block.timestamp , "over time");   

    require(KaleToken != address(0) , "didn't set Token address");

    require(lastClaimTime[3] + 30 days <= block.timestamp , "not claim time");

    

    require(remainAmounts[3] > 0, "distribution was done.");

    require(wallet4 !=address(0), "wallet4 must not be zero.");

    uint256 months = (block.timestamp - lastClaimTime[3]) / 30 days;

    uint256 distributeAmounts = months * distributeAmountsPerMonth[3];



    if(block.timestamp >= deadline[3]-40 days){

      distributeAmounts = remainAmounts[3];

      remainAmounts[3] = 0;

    }

    else{

      remainAmounts[3] -= distributeAmounts;

    }

    require(IERC20(KaleToken).balanceOf(address(this)) >= distributeAmounts, "balance of distributor contract is smaller than distributionAmounts.");

    IERC20(KaleToken).transfer(wallet4, distributeAmounts);    

    lastClaimTime[3] += 30 days * months;    

  }



  function distributeToWallet6() public onlyOwner{ 

    //require(deadline[5] >= block.timestamp , "over time");  

    require(KaleToken != address(0) , "didn't set Token address"); 

    require(lastClaimTime[5] + 30 days <= block.timestamp , "not claim time");

    

    require(remainAmounts[5] > 0, "distribution was done.");

    require(wallet6 !=address(0), "wallet6 must not be zero.");

    uint256 months = (block.timestamp - lastClaimTime[5]) / 30 days;

    uint256 distributeAmounts = months * distributeAmountsPerMonth[5];



    if(block.timestamp >= deadline[5]-35 days){

      distributeAmounts = remainAmounts[5];

      remainAmounts[5] = 0;

    }

    else{

      remainAmounts[5] -= distributeAmounts;

    }

    require(IERC20(KaleToken).balanceOf(address(this)) >= distributeAmounts, "balance of distributor contract is smaller than distributionAmounts.");

    IERC20(KaleToken).transfer(wallet6, distributeAmounts);    

    lastClaimTime[5] += 30 days * months;   

  }

  

}