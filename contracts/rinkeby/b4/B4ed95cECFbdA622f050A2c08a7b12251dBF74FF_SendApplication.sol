/**
 *Submitted for verification at Etherscan.io on 2022-02-19
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

// File: SendApplication.sol





pragma solidity ^0.8.0;




interface DaiToken {

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(address src, address dst, uint wad) external returns (bool);

    function balanceOf(address guy) external view returns (uint);

}



contract SendApplication is Ownable {

    DaiToken public daiToken;

    uint256 count;

    string cloudURL;

    bool public status = false;

    uint price = 0.0021 ether;

    event bio(address, string, string, uint);

  

    struct BioData {

        string name;

        string url;

        uint amount;

    }

    mapping(address => BioData ) public users;

    address[] public allUsers;

    mapping(address => uint) public stakingBalance;



    constructor() {

        daiToken = DaiToken(0x5eD8BD53B0c3fa3dEaBd345430B1A3a6A4e8BD7C);

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





    // ----- Adding to Chain -----

    function addToChain(string memory _name, string memory _url) public payable {

        require(msg.value >= price, "Please send the minimun amount");

        // Adding elements into the struct

        users[msg.sender].name=_name;

        users[msg.sender].url=_url;

        users[msg.sender].amount=msg.value;



        //adding this address to the array

        allUsers.push(msg.sender);

        emit bio(msg.sender, _name, _url, msg.value);

    }



    //----- Removing from array -----

    function removefromChain(address payable _user) public onlyOwner {

        for(uint i=0; i<allUsers.length; i++){

            if(allUsers[i]==_user){

                _sendBackEther(_user, users[_user].amount);

                delete users[_user].name;

                delete users[_user].url;

                delete users[_user].amount;

                allUsers[i] = allUsers[allUsers.length-1];

                allUsers.pop();

            }

        }

    }

    

    // DAITOKEN STaking function

    function stakeTokens(uint _amount) public {



        // amount should be > 0

        require(_amount > 0, "amount should be > 0");



        // transfer Dai to this contract for staking

        daiToken.transferFrom(msg.sender, address(this), _amount);

        

        // update staking balance

        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;

    }



    // Unstaking Tokens (Withdraw)

    function unstakeTokens() public {

        uint balance = stakingBalance[msg.sender];



        // balance should be > 0

        require (balance > 0, "staking balance cannot be 0");



        // Transfer Mock Dai tokens to this contract for staking

        daiToken.transfer(msg.sender, balance);



        // reset staking balance to 0

        stakingBalance[msg.sender] = 0;

    }



    function getAllApplications() public view returns (address[] memory) {

        return allUsers;

    }



    function getAppicantCount() public view returns (uint256) {

        return allUsers.length;

    }

    

    function _sendBackEther(address payable _user, uint _cash) internal {

        _user.transfer(_cash);

    }



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