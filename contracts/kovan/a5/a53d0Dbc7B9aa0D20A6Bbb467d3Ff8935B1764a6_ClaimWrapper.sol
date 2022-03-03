/**
 *Submitted for verification at Etherscan.io on 2022-03-03
*/

pragma solidity 0.6.12;



/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ClaimWrapper is Ownable {

    address public farmI;
    address public farmII;
    address public distributionI;
    address public distributionII;
    address public queryWrapper;

    constructor(address _farmI,address _farmII,address _distributionI,address _distributionII,address _queryWrapper) public {
        farmI = _farmI;
        farmII = _farmII;
        distributionI = _distributionI;
        distributionII = _distributionII;
        queryWrapper = _queryWrapper;
    }

    function claimFarmI(address user) public{
        bytes memory payload = abi.encodeWithSignature("claim(address)", user);
        address(farmI).call(payload);
    }

    function claimFarmII(address user) public {
        bytes memory payload = abi.encodeWithSignature("claim(address)", user);
        address(farmII).call(payload);
    }

    function claimFarm(address user) public{
        claimFarmI(user); 
        claimFarmII(user);
    }

    function claimDistributionI(address user) public{
        bytes memory payload = abi.encodeWithSignature("claimReward(address)", user);
        address(distributionI).call(payload);
    }

    function claimDistributionII(address user) public{
        bytes memory payload = abi.encodeWithSignature("claimReward(address)", user);
        address(distributionII).call(payload);
    }

    function claimDistribution(address user) public{
        claimDistributionI(user); 
        claimDistributionII(user);
    }

    function claimAll(address user) public{
        claimFarm(user);
        claimDistribution(user);
    }

    function farmIPending(address user) public view returns(uint256){
        bytes memory payload = abi.encodeWithSignature("pending(address)", user);
        (bool success,  bytes memory retuan_data) = address(farmI).staticcall(payload);
        if(success){
            return abi.decode(retuan_data,(uint256));
        }
        return 0;
    }

    function farmIIPending(address user) public view returns(uint256){
        bytes memory payload = abi.encodeWithSignature("pending(address)", user);
        (bool success,  bytes memory retuan_data)  = address(farmII).staticcall(payload);
        if(success){
            return abi.decode(retuan_data,(uint256));
        }
        return 0;
    }

    function pendingDistributionI(address user, bool borrowers, bool suppliers) public view returns(uint256){
        bytes memory payload = abi.encodeWithSignature("pendingRewardAccruedI(address,bool,bool)", user,borrowers,suppliers);
        (bool success,  bytes memory retuan_data) = address(queryWrapper).staticcall(payload);
        if(success){
            return abi.decode(retuan_data,(uint256));
        }
        return 0;
    }

    function pendingDistributionII(address user, bool borrowers, bool suppliers) public view returns(uint256){
        bytes memory payload = abi.encodeWithSignature("pendingRewardAccruedII(address,bool,bool)", user,borrowers,suppliers);
        (bool success,  bytes memory retuan_data) = address(queryWrapper).staticcall(payload);
        if(success){
            return abi.decode(retuan_data,(uint256));
        }
        return 0;
    }

    function pendingAll(address user) public view returns(uint256,uint256,uint256,uint256){
        return (
            farmIPending(user),
            farmIIPending(user),
            pendingDistributionI(user,true,true),
            pendingDistributionII(user,true,true)
        );
    }


    function update(address _farmI,address _farmII,address _distributionI,address _distributionII,address _queryWrapper) public onlyOwner{
        farmI = _farmI;
        farmII = _farmII;
        distributionI = _distributionI;
        distributionII = _distributionII;
        queryWrapper = _queryWrapper;
    }

}