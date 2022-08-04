/**
 *Submitted for verification at Etherscan.io on 2022-08-04
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
    function ownerOfNft(uint _id)external view returns(address);
    function upgradeToken(uint256 NftId,string memory rarity, uint256 nftIdToBurn,string memory tokenURI_) external;
    function rarityOfNft(uint256 nftId)external view returns(string memory);

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


    /**
    * @title "FulMint" contract.
    *       
    * @author Arpit Anand
    * @dev This smart contract is main contract which intract with FulNftGenerator contract to mint NFT
    *      This contact's functions is calling FULNftGenerator contract function to perform Mint, burn, Lock machanism.
    * 
    **/

contract FulMint is Ownable{

    using SafeMath for uint;
    using SafeERC20 for IERC20;
    
    address ful;
    IERC20 public fulToken;

    uint public packId;
  

    event whiteListed(string indexed WhitelistingConfirmation);  
    event blackListed(string indexed BlackListingConfirmation);
    event RemovedwhiteListedUser(string indexed RemoveFromWhitelist);
    event packIdMinted(uint indexed packid,uint256[] indexed nftIDs );
    
    mapping(uint256 => uint256) public ethPriceOfPack;       // Ehther Price of every pack.
    mapping(uint256 => uint256) public tokenPriceOfPack;     // Native Token(ERC20) price of every pack.
    mapping(address => uint) noOfBurnedNFT;                  // Burned NFT Id of user address.
    mapping(address => bool) public whitelistedAddresses;    // Whitelisted user by admin
    mapping(address => bool) public blackListedAddress;      // BlackListed user
    mapping(uint256 => bytes32) public rootOfPack;           // Storing root of all packs.
    mapping(address => uint256)public mintingCount;
    mapping(address => bool) public WhitelistedUserFreeMint;

    modifier isWhitelisted() {
      require(whitelistedAddresses[msg.sender] == true || WhitelistedUserFreeMint[msg.sender] == true, "Whitelist: You need to be whitelisted");
      _;
    }
    
    /**
    * @dev To set instance of native token and _FulNftGenerator contract 
    * @param _fulToken is the address of native token of platform
    * @param _FulNftGenerator is the ERC721 contact 
    *      
    **/
    constructor(address _fulToken, address _FulNftGenerator) {
        ful = _FulNftGenerator;
        fulToken = IERC20(_fulToken);
    }

    /**
     * @dev If some pack has need to updated or added so we need to update the root.
     *
     * @param packNumbers takes array of pack number.
     * @param root_ takes array of Root of packs.
     *
     **/
    function updateRoot(uint256[] memory packNumbers, bytes32[] memory root_)public onlyOwner{
        for(uint256 i = 0; i < packNumbers.length; i++){
            rootOfPack[packNumbers[i]] = root_[i];
        } 
        
    }

    /**
     * @dev The size of pack should be length of 13, same for the Root as well
     *
     * @param sizeOfPack Array Should must be length of 13.
     * @param rootHash Array of rootHash of packs.
     *
    **/

    function setRootOfPack(uint256[]memory sizeOfPack, bytes32[]memory rootHash) public onlyOwner{
        require(sizeOfPack.length <=13, "only 14 packs are allowed " );
        for(uint i=0; i<sizeOfPack.length;i++){
        rootOfPack[sizeOfPack[i]] = rootHash[i];
        }
    }

    
    /**
     * @dev one time a user can buy one pack only, by using this function pack can be bought by native token of platform.
     *      Only whiteListed user can buy Pack.
     *
     * @param _leaf takes 3 length of array of leafHash of NFT.
     * @param _proof takes array of hash to verify desired leaf is stored on IPFS or not.
     * @param  _noOfPack basically players are shorted inorder to rarity so in every pack there are set of players.
     * @param nftIDs takes array length of 3 NFT Id, which is passed by frontend.
     * @param nftName takes array length of 3 NFT player name.
     * @param tokenUri takes array length of 3 NFT matadata path of IPFS.
     * @param nftPosition To set Every NFT of their position of playing area like he is midfielder, attacker or defender.
     * @param nftRarity To set rarity of NFT.
     *
     **/
    function buyPackOfNFTByToken( bytes32[] memory _leaf, bytes32[][] memory _proof, uint _noOfPack,uint256[] memory nftIDs,string[] memory nftName, string[] memory tokenUri, string[] memory nftPosition,string[] memory nftRarity)public isWhitelisted{
        require(_noOfPack <= 13, "You can't buy more than 13 packs");
        require(verifyPacks(rootOfPack[_noOfPack], _leaf,_proof) == true);
        require(mintingCount[msg.sender]<5,"A user can mint NFT 5 times only ");
    
        uint amount = tokenPriceOfPack[_noOfPack];
        fulToken.safeTransferFrom(msg.sender,address(this), amount);

        //uint totalNFT = _noOfPack.mul(3);
        
        for(uint256 i=0;i<3;i++){
            interfaceful(ful).mintNFT(nftIDs[i], nftName[i],tokenUri[i], msg.sender, nftPosition[i],nftRarity[i]);
        }
        packId++;
        mintingCount[msg.sender] = mintingCount[msg.sender].add(1);
        emit packIdMinted(packId, nftIDs);

    }

    /**
     * @dev one time a user can buy one pack only, by using this function pack can be bought by ETH only.
     *      Only whiteListed user can buy Pack.
     *
     * @param _leaf takes 3 length of array of leafHash of NFT.
     * @param _proof takes array of hash to verify desired leaf is stored on IPFS or not.
     * @param  _noOfPack basically players are shorted inorder to rarity so in every pack there are set of players.
     * @param nftIDs takes array length of 3 NFT Id, which is passed by frontend.
     * @param nftName takes array length of 3 NFT player name.
     * @param tokenUri takes array length of 3 NFT matadata path of IPFS.
     * @param nftPosition To set Every NFT of their position of playing area like he is midfielder, attacker or defender.
     * @param nftRarity To set rarity of NFT.
     *
    **/

    function buyPackOfNFTByEth( bytes32[] memory _leaf, bytes32[][] memory _proof, uint _noOfPack,uint256[] memory nftIDs,string[] memory nftName, string[] memory tokenUri, string[] memory nftPosition,string[] memory nftRarity)public payable isWhitelisted{
        require(_noOfPack <= 13, "You can't buy more than 13 packs");
        require(verifyPacks(rootOfPack[_noOfPack], _leaf,_proof) == true);
        require(mintingCount[msg.sender]<5,"A user can mint NFT 5 times only ");

        if(WhitelistedUserFreeMint[msg.sender]){
            for(uint256 i=0;i<3;i++){
            interfaceful(ful).mintNFT(nftIDs[i], nftName[i],tokenUri[i], msg.sender, nftPosition[i],nftRarity[i]);
            }
            packId++;
            mintingCount[msg.sender] = mintingCount[msg.sender].add(1);
            emit packIdMinted(packId, nftIDs);
        }else{
            uint amount = ethPriceOfPack[_noOfPack];
            require(amount == msg.value,"Pack price Error");
        
            for(uint256 i=0;i<3;i++){
            interfaceful(ful).mintNFT(nftIDs[i], nftName[i],tokenUri[i], msg.sender, nftPosition[i],nftRarity[i]);
            }
            packId++;
            mintingCount[msg.sender] = mintingCount[msg.sender].add(1);
            emit packIdMinted(packId, nftIDs);
        }
        

    }

    
    /**
     * @dev To proof leaf that exist in merkle tree or not we need proof path of Leaf.
     *      called internally by 'buyPack' function.
     *
     * @param root_ takes root hash of merkle tree.
     * @param _leaf takes array of leaf hash.
     * @param _proof path of leaf hash.
     *
     * @return if leaf is existing is root then it will return true otherwise return false.
     **/
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

    /**
     * @dev admin needs to allow user to use platform to mint NFT on their address,
     *      To allow user, needs to whiteList user first.
     *
     * @param _addressToWhitelist List of array of user whome admin wants to whitelist.
     *
     **/
    function addUserToWhiteList(address[] memory _addressToWhitelist) public onlyOwner {
      for(uint i=0;i<_addressToWhitelist.length;i++){
            whitelistedAddresses[_addressToWhitelist[i]] = true;
        }
      emit whiteListed("WhiteListing Done");
      
    }

    function addUserToWhiteListForFreeMint(address[] memory _addressToWhitelist) public onlyOwner {
      for(uint i=0;i<_addressToWhitelist.length;i++){
            WhitelistedUserFreeMint[_addressToWhitelist[i]] = true;
        }
      emit whiteListed("WhiteListing Done");
      
    }

    /**
     * @dev admin can remove user from whitelist.
     *     
     * @param _addressToRemove List of array of user whome admin wants to remove from whitelist.
     *
    **/

    function removeWhiteListedUser(address[]memory _addressToRemove)public onlyOwner{
      for(uint i=0;i<_addressToRemove.length;i++){
            whitelistedAddresses[_addressToRemove[i]] = false;
      }
      emit RemovedwhiteListedUser("User removed");
    }

    /**
     * @dev admin can Blacklist user to not use thair plateform.
     *     
     * @param _addressToBlackList List of array of user whome admin wants to blacklist.
     *
    **/
    function addUserToBlackList(address[] memory _addressToBlackList) public onlyOwner {
      for(uint i=0;i<_addressToBlackList.length;i++){
            blackListedAddress[_addressToBlackList[i]] = true;
      }
      emit blackListed("BlackListing Done");
      
    }

    // To Check address is whiteListed or Not.
    function verifyUser(address _whitelistedAddress) public view returns(bool) {
      bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
      return userIsWhitelisted;
    }

    /**
     * @dev Before minting owner needs to set every pack price in ETH.
     *
     * @param packNumber takes array of pack number to set price for each pack.
     * @param _price of each pack in ETH.
     *
     **/
    function setPackPriceForEth(uint256[]memory  packNumber, uint256[]memory _price)public onlyOwner{
        for(uint256 i; i < packNumber.length; i++){
            ethPriceOfPack[packNumber[i]] = _price[i];
        }   
    }

    /**
     * @dev Before minting owner needs to set every pack price in native Token.
     *
     * @param packNumber takes array of pack number to set price for each pack.
     * @param _price of each pack in native Token.
     *
    **/
    function setPackPriceForToken(uint256[]memory  packNumber, uint256[]memory _price)public onlyOwner{
        for(uint256 i; i < packNumber.length; i++){
            tokenPriceOfPack[packNumber[i]] = _price[i];
        }   
    }

   
    /**
    * @dev if user want to burn their NFT they can burn and after burning 3 NFT user will get 1 random NFT.
    *
    * @param NftID is list of NFT id user want to burn.
    * @param _leaf is which leaf of nft will be mint to user who has burned 3 NFT.
    * @param nftId is id of NFT which user will get.
    * @param nftName takes NFT player name.
    * @param tokenUri takes NFT matadata path of IPFS.
    * @param nftPosition To set NFT of their position of playing area like he is midfielder, attacker or defender.
    * @param nftRarity To set rarity of NFT.
    **/
    function burnNFTId(uint256[]memory NftID, bytes32  _leaf, bytes32[] memory _proof, uint256 nftId, string memory nftName,string memory tokenUri,string memory nftPosition, string memory nftRarity)public {
        require(verify(rootOfPack[14], _leaf,_proof) == true);
        for(uint i = 0; i<=2; i++){
            require(interfaceful(ful).ownerOfNft(NftID[i]) == msg.sender," Only NFT owner can burn token  ");
            interfaceful(ful).burnNFT(NftID[i]);
            noOfBurnedNFT[msg.sender] = noOfBurnedNFT[msg.sender].add(1);
            if(noOfBurnedNFT[msg.sender] == 3){
                noOfBurnedNFT[msg.sender]=0;
                //fulToken.transfer(msg.sender,1);
                interfaceful(ful).mintNFT(nftId, nftName,tokenUri, msg.sender, nftPosition,nftRarity);
            }
        }
    } 

    
    /**
     * @dev if any user or admin want to lock their NFT for perticular amount of time they can achieve with this function.
     *
     * @param _id is which id user or admin wants to lock.
     * @param _duration is the time in which NFT will be locked.
     *
     **/
    function toLockNFT(uint[] memory _id, uint _duration)public { 
        require(_id.length == 15,"Array of Ids should be length of 15");
        for(uint i = 0 ;i <_id.length;i++ ){
            require(interfaceful(ful).ownerOfNft(_id[i]) == msg.sender," Only NFT owner can lock  ");
            interfaceful(ful).toLockId(_id[i], _duration);
        }
    }

    /**
     * @dev if any user want to upgrade their NFT rarity then user need to burn  
     *       To upgrade common to Rare user need to pay 500 native token .
     *       To upgrade rare to legendary user need to pay 1000 native token. 
     *
     * @param NftId which user wants to upgrade.
     * @param rarity current rarity of id which user wants to upgrade.
     * @param nftIdToBurn this NFT id should be "rare" rarity.
     * @param tokenURI_ updated uri of NFT.
     *
    **/
    function upgradeNftRarity(uint256 NftId,string memory rarity, uint256 nftIdToBurn,string memory tokenURI_ )public  {
        require(keccak256(bytes(interfaceful(ful).rarityOfNft(nftIdToBurn))) == keccak256(bytes("rare")),"Only rare Nft is allowed burn");
        require(interfaceful(ful).ownerOfNft(NftId) == msg.sender," Only NFT owner can Upgrade Token ");
        require(interfaceful(ful).ownerOfNft(nftIdToBurn) == msg.sender," Only NFT owner can Burn Their Token ");

        if(keccak256(bytes(rarity)) == keccak256(bytes("common"))){
            fulToken.safeTransferFrom(msg.sender,address(this), 500);
        }

        if(keccak256(bytes(rarity)) == keccak256(bytes("rare"))){
            fulToken.safeTransferFrom(msg.sender,address(this), 1000);
        }
        interfaceful(ful).upgradeToken(NftId,rarity,nftIdToBurn,tokenURI_);
        
    }

    /**
     * @dev Safely transfers `tokenId` token from `userAddress` to `to`.
    **/
    function tansferNFT(address to, uint _id)public  {
        interfaceful(ful).transferFrom(msg.sender, to, _id);
    }

    /**
     * @dev Returns the number of tokens in contract address.
    **/
    function balanceOf()public view returns(uint){
        return fulToken.balanceOf(address(this));

    }

    /**
     * @dev Returns the ETH stored in contract address.
    **/
    function ethBalance()public view returns(uint256){
        return address(this).balance;
    }

    receive() external payable {
        // React to receiving ether
    }

    function withdrawEther() public onlyOwner  {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }

    function withdrawToken(uint _amount)public onlyOwner{
        fulToken.transfer(msg.sender, _amount);
    }


}