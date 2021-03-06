/**
 *Submitted for verification at Etherscan.io on 2022-03-21
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
   // ??????????????????????????????200??????
    uint16 public arrayLimit = 200;
   //?????????????????????

   constructor ()  {

   }

   //NFT
   enum NFTState {Undetected,Detected}
   struct NFT{
       NFTState state;//???????????????
       string hash;//NFT?????????
       string IPFS; //NFT???IPFS
       bool isDetected; // ??????????????????
       bool result; //????????????
       address uploader;// ?????????
   }
   uint public ID = 1;//?????????????????????NFT??????
   mapping(uint=>NFT) private nfts; 
   
   //??????NFT????????????????????????????????????(??????????????????)
   function checkNFTByHash(string memory _hash) public view returns(bool) {
       for(uint i=0;i<ID;i++){
            if(compareStrings(nfts[i].hash,_hash)&&nfts[i].result==true){
                return true;
            }
        }
        return false;
   }
   //??????NFT???????????????????????????????????????????????????1 ??????????????????
   function checkNFTByID(uint _ID) public view returns(bool){
    //    require(msg.sender == owner,"Only owner can check the NFT by ID!");
       require(_ID<ID,"This ID of NFT don't exists");
       NFT memory nft = nfts[_ID];
       return nft.result;
   }
    //??????NFT???????????????????????????????????????????????????2 ??????NFT??????
   function checkNFTByIDDetail(uint _ID) public view returns(NFT memory){
    //    require(msg.sender == owner,"Only owner can check the NFT by ID!");
       require(_ID<ID,"This ID of NFT don't exists");
       NFT memory nft = nfts[_ID];
       return nft;
   }
   
   //NFT??????
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

    //NFT?????????????????? ??????*
    function detectNFT(uint _ID,bool _result) public onlyOwner{
        // require(msg.sender == owner,"Only owner can detect the NFT!");
        require(nfts[_ID].isDetected==false&&nfts[_ID].state==NFTState.Undetected,"The NFT does not meet the detection conditions!");
        nfts[_ID].result = _result;
        nfts[ID].isDetected = true;
        nfts[ID].state = NFTState.Detected;
   }
    //NFT???????????????????????? ??????*
    function batchDetectNFT(uint[] memory _ID,bool[] memory _result) public onlyOwner{
        // ???????????????????????????????????????????????????
        require(_ID.length <= arrayLimit, "length beyond arrayLimit");

        // ??????????????????????????????
        require(_ID.length==_result.length,"The length of _ID should equal to the length of _result");

        for(uint8 i = 0; i < _ID.length; i++){
            uint nftid = _ID[i];
            bool resulti = _result[i];
            require(nfts[nftid].isDetected==false&&nfts[nftid].state==NFTState.Undetected,"The NFT does not meet the detection conditions!");
            nfts[nftid].result = resulti;
            nfts[nftid].isDetected = true;
            nfts[nftid].state = NFTState.Detected;
        }
       
   }
   
   //?????????NFT?????????????????????????????????NFT?????????????????????
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