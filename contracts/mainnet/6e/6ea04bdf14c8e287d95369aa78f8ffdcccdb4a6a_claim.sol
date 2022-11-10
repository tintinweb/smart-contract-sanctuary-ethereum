/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
 contract Ownable  {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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


contract claim is Ownable{

    mapping(IERC20=> mapping(address =>uint256 )) public allowance; 
    bool public claimPeriod;
    constructor() {
        claimPeriod=true;
    }
    // only the valid addresses can claimed assigned amount of tokens
    // contract must have enough balance to send claimable
    function claimAirdrop(IERC20 _token) external {
        require(claimPeriod==true,"Claim Periods Ends");
        IERC20 token= _token;
        uint256 claimable=allowance[token][msg.sender];
        require(claimable>=0,"You are not claimer");
        require(token.balanceOf(address(this))>=claimable,"Contract is ran out of funds!");
        token.transfer(msg.sender, claimable);
        allowance[token][msg.sender]=0;
    }

    // only contract owner can set the claimer and assigned the amount to them
    function setClaimers(IERC20 _token,address[] memory _addr,uint256[] memory _amounts) external onlyOwner{

         for (uint256 i=0; i < _addr.length; i++) {
            allowance[_token][_addr[i]]+=_amounts[i];
            }
    }

    // owner of this contract withdraw the any erc20 stored in the contract to own address
    function emergencyWithdraw(IERC20 _token,uint256 _tokenAmount) external onlyOwner {
         IERC20(_token).transfer(msg.sender, _tokenAmount);
    }

    // owner of this contract withdraw the ether stored in the contract to own address

    function emergencyWithdrawETH(uint256 Amount) external onlyOwner {
        payable(msg.sender).transfer(Amount);
    }
    
    // owner change the claimPeriod to true/false
    function FlipclaimPeriod(bool _status) external onlyOwner{
        claimPeriod=_status;
    }



}