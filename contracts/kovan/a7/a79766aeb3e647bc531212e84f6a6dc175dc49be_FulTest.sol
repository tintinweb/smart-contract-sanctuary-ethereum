/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.7;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return payable(address(uint160(account)));
    }
    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{value:(amount)}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

   
    constructor() {
        _setOwner(_msgSender());
    }

  
    function owner() public view virtual  returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

   
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface interfaceful{
    function mintNFT(uint256 tokenId,string memory name, string memory tokenURI_,address user,string memory position, string memory rarity) external;
    function toLockId(uint _id, uint duration)external;
    function transferFrom(address from,address to,uint256 tokenId) external;
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes memory _data) external;
    function burnNFT(uint256 tokenId)external;
    function getNFTCount() external view returns (uint256);
    function ownerOfNft(uint _id)external view returns(address);
    function rarityOfNFT(uint _id)external view returns(uint);
    function positionOfNFT(uint _id)external view returns(uint);

}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
         
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


contract FulTest is Ownable{

    using SafeMath for uint;
    using SafeERC20 for IERC20;
    
    address ful;
    IERC20 public fulToken;
  

    event whiteListed(string indexed WhitelistingConfirmation);
    event blackListed(string indexed BlackListingConfirmation);
    event RemovedwhiteListedUser(string indexed RemoveFromWhitelist);
    
    mapping(uint => uint) public priceOfPack;
    mapping(address => uint) noOfBurnedNFT;
    mapping(address => bool) public whitelistedAddresses;
    mapping(address => bool) public blackListedAddress;
    mapping(uint256 => bytes32) public rootOfPack;

    modifier isWhitelisted() {
      require(whitelistedAddresses[msg.sender] == true, "Whitelist: You need to be whitelisted");
      _;
    }
    

    constructor(address _fulToken, address _FulNftGenerator) {
        ful = _FulNftGenerator;
        fulToken = IERC20(_fulToken);
    }

    bytes32 _root = 0x92c160dca7b5340b82b7ab4f17123354654f3c98661cca102b8f7b109540ea5e;

    function updateRoot(bytes32 root_)public onlyOwner{
        _root = root_;
    }

    function setRootOfPack(uint256 packNumber, bytes32 rootHash) public onlyOwner{
        require(packNumber <=13, "pack number should be in between one to thirteen only " );
        rootOfPack[packNumber] = rootHash;
    }
    
    function buyPackOfNFT( bytes32[] memory _leaf, bytes32[][] memory _proof, uint _noOfPack,uint256[] memory nftIDs,string[] memory nftName, string[] memory tokenUri, string[] memory nftPosition,string[] memory nftRarity)public isWhitelisted{
        require(_noOfPack <= 13, "You can't buy more than 13 packs");
        require(verifyPacks(rootOfPack[_noOfPack], _leaf,_proof) == true);
    
        // uint amount = _noOfPack.mul(priceOfPack[1]);
        // fulToken.safeTransferFrom(msg.sender,address(this), amount);

        //uint totalNFT = _noOfPack.mul(3);
        
        for(uint256 i=0;i<3;i++){
            interfaceful(ful).mintNFT(nftIDs[i], nftName[i],tokenUri[i], msg.sender, nftPosition[i],nftRarity[i]);
        }

    }

    // function nftForWhitelistedUser()public isWhitelisted(msg.sender) {
    //     buyPackOfNFT(5);
    // }

    function verifyPacks(bytes32 root_, bytes32[] memory _leaf, bytes32[][] memory _proof) public pure returns(bool) {
        for(uint256 i=0; i<3; i++){
            if(verify(root_, _leaf[i], _proof[i]) == false){
                return false;
            }
        }
        return true;
    }

    function verify(bytes32 root, bytes32 leaf, bytes32[] memory proof)public pure returns (bool){
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
            // Hash(current computed hash + current element of the proof)
            computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            }   else {
            // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

    function addUserToWhiteList(address[] memory _addressToWhitelist) public onlyOwner {
      for(uint i=0;i<_addressToWhitelist.length;i++){
            whitelistedAddresses[_addressToWhitelist[i]] = true;
      }
      emit whiteListed("WhiteListing Done");
      
    }

    function removeWhiteListedUser(address[]memory _addressToRemove)public onlyOwner{
      for(uint i=0;i<_addressToRemove.length;i++){
            whitelistedAddresses[_addressToRemove[i]] = false;
      }
      emit RemovedwhiteListedUser("User removed");
    }

    function addUserToBlackList(address[] memory _addressToBlackList) public onlyOwner {
      for(uint i=0;i<_addressToBlackList.length;i++){
            blackListedAddress[_addressToBlackList[i]] = true;
      }
      emit blackListed("BlackListing Done");
      
    }

    function verifyUser(address _whitelistedAddress) public view returns(bool) {
      bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
      return userIsWhitelisted;
    }


    function setPackPrice(uint _price)public onlyOwner{
        priceOfPack[1] = _price;
    }

    // function buyPack(uint _noOfPack)public{
    //     require(_noOfPack <= 13, "You can't buy more than 13 packs");
    //     uint amount = _noOfPack.mul(priceOfPack[1]);
    //     fulToken.safeTransferFrom(msg.sender,address(this), amount);

    //     uint totalNFT = _noOfPack.mul(3);
    
    //     for(uint i=0 ;i<totalNFT;i++){
    //         interfaceful(ful).mintNFT(id, "TOkenUri", msg.sender);
    //         id++;
    //     }

    // }

    // function burnNFTId(uint tokenID)public {
    //     require(interfaceful(ful).ownerOfNft(tokenID) == msg.sender," Only NFT owner can burn token  ");
    //     interfaceful(ful).burnNFT(tokenID);
    //     noOfBurnedNFT[msg.sender] = noOfBurnedNFT[msg.sender].add(1);
    //     if(noOfBurnedNFT[msg.sender] == 3){
    //         noOfBurnedNFT[msg.sender]=0;
    //         fulToken.transfer(msg.sender,1);
    //         interfaceful(ful).mintNFT(id, "TOkenUri", msg.sender);
    //     }
    // } 

    function balanceOf()public view returns(uint){
        return fulToken.balanceOf(address(this));

    }

    function toLockNFT(uint[] memory _id, uint _duration)public { 
        require(_id.length == 15,"Array of Ids should be length of 15");
        for(uint i = 0 ;i <_id.length;i++ ){
            require(interfaceful(ful).ownerOfNft(_id[i]) == msg.sender," Only NFT owner can lock  ");
            interfaceful(ful).toLockId(_id[i], _duration);
        }
    }

    function tansferNFT(address to, uint _id)public  {
        interfaceful(ful).transferFrom(msg.sender, to, _id);
    }

}