/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/[email protected]/utils/Context.sol


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

// File: @openzeppelin/[email protected]/access/Ownable.sol


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

// File: branch.sol


pragma solidity ^0.8.4;


contract FMG is Ownable{

    string private _name = "FMG";
    string private _symbol = "FMG";
    function name() public view virtual returns (string memory) {
        return _name;
    }
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    //合约分账
    bool private locked = false; //转账开关
    uint256  shareamount = 0.01 ether;  //默认瓜分额

    address[] public partition = [0xC52318EF9f7F2369532A0Fcd574A4a6949a990F7,0x45Cf1ea0B9300eEeCC9401aeC26026D17C1e9e1a,0xB7D250d516D9A1CE2C66482eEC8fD698992A0D4B,0x6af1995C77B8D71cdc637D7578996d68566f1a81,0x0F00E39ac3EEB521716c3e6557A8CbF9D709a324,0x2EcBbEe7EcA1629D55330aa0f814cb0FF8F00044,0xBa1381EA6C57E9C181Dd49c72160CCC0A21f92f1,0x7Dcb9c9Ba9c814F6292Ed08578679889ea6c87f4,0xF938C64Ee25152af903c5C173B4808157E078a42,0x0dc3f4698C7De825493E1AEBFd0C0845456b75A0];
    uint[] public partitionRatio= [5,10,10,10,10,10,10,3,30,2];

    receive() external payable {} 
    //设置瓜分ETH
    function setEth(uint _eth) public onlyOwner
    {
        shareamount = _eth;
    }
    //获取开关状态
    function getEth() public view returns(uint)
    {
        return shareamount;
    }

    //瓜分账户
    function getPartition() public view returns(address[] memory)
    {
        return partition;
    }
    //瓜分比例
    function getPartitionRatio() public view returns(uint[] memory)
    {
        return partitionRatio;
    }

    //修改瓜分比例
   function setPartition(address _setAddress,uint _proportion) public returns(address,uint){

        for(uint i=0; i < partition.length;i++){
            if(partition[i] == _setAddress){
                partitionRatio[i]=_proportion;
            }
        }
        return (_setAddress,_proportion);

    }

    //查询地址比例
    function lookPartition(address _lookAddress) public view returns(address,uint){

        for(uint i=0; i < partition.length;i++){
            if(_lookAddress == partition[i]){
                return (_lookAddress,partitionRatio[i]);
            }
        }
        return (_lookAddress,0);
    }

    //设置开关
    function setLocked(bool _locked) public onlyOwner
    {
        locked = _locked;
    }
    //获取开关状态
    function getLocked() public view returns(bool)
    {
        return locked;
    }
    //获取金额
    function getUserBalance(address _address) public view returns (uint256){
        return _address.balance;
    }

    function getOwnerBlance() public view returns (uint) {
        return address(this).balance;
    }

    function getUserBlance() public view returns (uint) {
        return msg.sender.balance;
    }

    //转账
    function transferAccounts(address _address,uint num) private{

        require(num >= 0 && num < 1 ether , "num 1!");//最大限制
        payable(_address).transfer(num) ;
        
    }

    //进行分账
    function fashionable() public  onlyOwner ()
    {

        uint amount;
        require(!locked, " lock!");//防止攻击
        amount=getOwnerBlance();
		uint256 _shareamount = shareamount;
        require(amount >= _shareamount,"Can divide the amount is insufficient");
		address[] memory _partition = partition;
		uint256[] memory _partitionRatio = partitionRatio;
		locked = true;
        for(uint i=0;i<partition.length;i++){
			transferAccounts(_partition[i], _shareamount*_partitionRatio[i]/100);
		}

        locked = false;

    }

}