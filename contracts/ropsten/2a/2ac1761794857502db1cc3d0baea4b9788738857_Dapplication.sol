/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

// SPDX-License-Identifier: UNLICENSED
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

// File: Desktop/00 - Remix Folder/Fiver/fiverNoxj/SendApplication2.sol



pragma solidity ^0.8.0;


interface DaiToken {
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
}

contract Dapplication is Ownable {
    DaiToken public daiToken;
    uint price = 10;
    address[] public allApplicants;
    mapping(address => uint) public DaiBalance;

    constructor() {
        daiToken = DaiToken(0x3580dc1c809905c8621546d2B2Ae7C67ed32085C);
    }
    
    //========================
    function contractBalance() public view returns(uint){
        return address(this).balance;
    }
    
    // ---------Price updation--------------
    function updatePrice(uint _newPrice) public returns(uint){
        price = _newPrice;
        return price;
    }

    
    // Send Application
    function sendApplication(uint _amount) public {

        // amount should be > 0
        require(_amount > 0, "amount should be > 0");

        // transfer Dai to this contract for staking
        daiToken.transferFrom(msg.sender, address(this), _amount);
        
        // update staking balance
        DaiBalance[msg.sender] += _amount;
        allApplicants.push(msg.sender);
        // allUsers.push(msg.sender);
    }

    // Accept Application
    function acceptApplication(uint _applicationNo, address _withdrawTo) external onlyOwner {
        uint balance = DaiBalance[msg.sender];

        // balance should be > 0
        require (balance > 0, "staking balance cannot be 0");

        // Transfer Mock Dai tokens to this contract for staking
        daiToken.transfer(_withdrawTo, balance);

        // reset staking balance to 0
        DaiBalance[msg.sender] = 0;
        _removefromChain(_applicationNo);
    }

    // Rejecting Application
    function rejectApplication(uint _index) public onlyOwner{
        uint balance = DaiBalance[msg.sender];

        // balance should be > 0
        require (balance > 0, "staking balance cannot be 0");

        // Transfer Mock Dai tokens to this contract for staking
        daiToken.transfer(msg.sender, balance);

        // reset staking balance to 0
        DaiBalance[msg.sender] = 0;
         _removefromChain(_index);
    }

    // For removing item from Chain ..
    function _removefromChain(uint _index) internal {
            allApplicants[_index] = allApplicants[allApplicants.length-1];
            allApplicants.pop();
            // allApplicants -= 1;
    }

    function getAllApplications() public view returns (address[] memory) {
        return allApplicants;
    }

    function getAppicantCount() public view returns (uint256) {
        return allApplicants.length;
    }
    
    // function _sendBackEther(address payable _user, uint _cash) internal {
    //     _user.transfer(_cash);
    // }

    // Withdrawing ether to wallet of owner
    function withdraw(address payable _to) external payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ethers available");
        // _to.transfer(balance); Became obsolete now after May 2021
        (bool success, ) = (_to).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    // ----- Removing from array in order -----
    // function removefromChain(address _user) public onlyOwner {
    //     one_user.remove(_user);
        
        // count -= 1;

        // emit BioDataEntered(_applicant, _firstName, _lastName, _city, _country, _email, _videoURL);
    // }

    // ----- Removing from array in no order. Copy the last element and paste it in the removing index. cost less fees -----
/*    function removefromChain(uint _index) external onlyOwner {
        applicantCount -= 1;
            one_user[_index] = one_user[one_user.length-1];
            one_user.pop();
    }
*/
    // function decision() public{
    //     if(status = true){
    //         addToBlockchain(address, string, string, string, string, string, string);
    //     }
    // }

}