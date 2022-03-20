/**
 *Submitted for verification at Etherscan.io on 2022-03-20
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

// File: contracts/oracle.sol



pragma solidity >=0.7.0 <0.9.0;



contract NFTOracle is Ownable{
   
   //预言机合约部署

   constructor ()  {

   }

   //NFT
   enum NFTState {Undetected,Detected}
   struct NFT{
       NFTState state;//目前的状态
       string hash;//NFT哈希值
       string IPFS; //NFT的IPFS
       bool isDetected; // 是否经过检测
       bool result; //检测结果
       address uploader;// 送检者
   }
   uint public ID = 1;//检测系统中所有NFT编号
   mapping(uint=>NFT) private nfts; 
   
   //输入NFT哈希，查看其是否通过检测(可供用户调用)
   function checkNFTByHash(string memory _hash) public view returns(bool) {
       for(uint i=0;i<ID;i++){
            if(compareStrings(nfts[i].hash,_hash)&&nfts[i].result==true){
                return true;
            }
        }
        return false;
   }
   //输入NFT编号，查看送检情况（供检测者调用）
   function checkNFTByID(uint _ID) public view returns(bool){
    //    require(msg.sender == owner,"Only owner can check the NFT by ID!");
       require(_ID<ID,"This ID of NFT don't exists");
       NFT memory nft = nfts[_ID];
       return nft.result;
   }
   
   //NFT送检
   function uploadNFT(string memory _hash,string memory _ipfs)  public returns(uint256){
       require(hashIsExists(_hash)&&ipfsIsExists(_ipfs),"Unable to repeat the detection!");
       nfts[ID].hash = _hash;
       nfts[ID].IPFS = _ipfs;
       nfts[ID].state = NFTState.Undetected; 
       nfts[ID].isDetected = false;
       nfts[ID].result = false;
       nfts[ID].uploader = msg.sender;
       ID = ID+1;
       return ID-1;
   }

    //NFT检测情况更新
    function detectNFT(uint _ID,bool _result) public onlyOwner{
        // require(msg.sender == owner,"Only owner can detect the NFT!");
        require(nfts[_ID].isDetected==false&&nfts[_ID].state==NFTState.Undetected,"The NFT does not meet the detection conditions!");
        nfts[_ID].result = _result;
        nfts[ID].isDetected = false;
        nfts[ID].state = NFTState.Detected;
   }
   
   //判断该NFT是否满足检测条件，即该NFT是否已经送检过
    function  hashIsExists(string memory _hash) private view returns(bool){
        for(uint i=0;i<ID;i++){
            if(compareStrings(nfts[i].hash,_hash)){
                return false;
            }
        }
        return true;
    }
    function ipfsIsExists(string memory _ipfs) private view returns(bool){
        for(uint i=0;i<ID;i++){
            if(compareStrings(nfts[i].IPFS,_ipfs)){
                return false;
            }
        }
        return true;
    }
    
    function  compareStrings(string memory a, string memory b) private pure returns(bool) {
           return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }



}