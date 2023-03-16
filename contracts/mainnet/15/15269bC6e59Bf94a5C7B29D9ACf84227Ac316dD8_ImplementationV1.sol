// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {Implementation} from "./Implementation.sol";

contract ImplementationV1 is Implementation{
    
    /**    
     * @dev depositNFTs fractor deposit NFTs to lock these NFTs
     * ** Params **
     *  addrs collection address
     *  tokenIds tokenId
     *  tokenTypes 0: ERC721, 1: ERC1155
     *  amount NFT amount: If token type is ERC721, amount = 1
     */
    function depositNFTs(
        address [] memory ,
        uint256 [] memory ,
        uint256 [] memory ,
        uint256 [] memory ,
        bytes memory,
        string memory
    ) public{
        _delegatecall(DepositHandler);
    }

    /**    
     * @dev redeemNFT Super Admin can transfer NFTs to user
     * ** Params **
     * tokenId
     * nftTypes 0: ERC721, 1: ERC1155
     * tokenAmountd NFT amount: If token type is ERC721, amount = 1
     * collectionAddrs collection address
     * receiver receiver
     * requestId
     */
    function redeemNFT(
        uint256[] memory ,
        uint256[] memory ,
        uint256[] memory ,
        address[] memory ,
        address,
        string memory 
    ) public{
        _delegatecall(DepositHandler);      
    }

    /** 
     * @dev mintNFT mint NFT that represent for fractor 's asset
     * ** Params **
     * chainId chainId of the NFT
     *  collectionAddresses collection address
     *  tokenIds tokenId
     *  nftTypes 0: ERC721, 1: ERC1155
     *  tokenAmounts NFT amount: If token type is ERC721, amount = 1
     */
    function mintNFT(
        uint256,
        uint256 ,
        uint256[] memory ,
        uint256[] memory ,
        uint256[] memory ,
        address[] memory ,
        string memory

    ) public{
        _delegatecall(NFTHandler);
    }
    /** 
     * @dev mintFNFT fractionalize NFTs
     * ** Params **
     * token id of fractionalized NFTs 
     * FNFT amount
     * FNFT name
     * FNFT symbol
     * FNFT id
     * fractor id
     */
    function mintFNFT(
        uint256[] memory ,
        uint256 ,
        string memory,
        string memory,
        string memory,
        bytes memory
        ) public  {
            _delegatecall(NFTHandler);
    }

    /**
     * @dev getNFT user who own 100% FNFT of an IAO event can claim the NFTs
     * ** Params **
     * tokenAddr FNFT contract address
     */
    function getNFT(address) public{
        _delegatecall(NFTHandler);

    }

    /**
     * @dev createIAOEvent
     * ** Params **
     * @param (0) threshold, (1) startDate, (2) endDate, (3) limit
     * @param (0) tokenAddr token used to buy FNFT, if tokenAddr = address(0) => native token (1) FNFT address
     * @param (0) fractorId, (1) iaoId
     */
    function createIAOEvent(
        uint256 [] memory,
        address[] memory,
        bytes[] memory
    ) public{
        _delegatecall(IAOHandler);
    }


    /**
     * @dev buyFNFT user buy FNFT, in vault period, user can claim their FNFT after the event end
     * ** Params **
     * @param (0) tokenAmount, (1) fund
     * @param (0) buyer
     * BuyRequest signature
     * internal transaction id
     */
    function buyFNFT(
        uint256[] memory, 
        address[] memory,
        bytes memory,
        bytes memory,
        bytes memory
    ) public payable{
        _delegatecall(IAOHandler);

    }

    /**
    * @dev deactivate the FNFT
    * address of the FNFT contract
     */
    function deactivateFNFT(
        address 
    ) public{
        _delegatecall(NFTHandler);
    }

    /**
    * @dev deactivate IAO event
    * iaoId
     */
    function deactivateIAOEvent(
        bytes memory
    ) public {
        _delegatecall(IAOHandler);
    }

    /**
     * @dev fractorClaim fractor can claim their FNFT and revenue after the IAO event end
     * ** Params **
     *  receiver receiver
     *  ids iaoId
     */
    function fractorClaim(
        address ,
        bytes[] memory
    ) public  payable {
        _delegatecall(IAOHandler);
    }  

    /**
     * @dev withdrawFund if the vault period failed, user can claim their fund back
     * ** Params **
     * id IAO event id
     */
    function withdrawFund(bytes memory) public payable{
        _delegatecall(IAOHandler);
    }  

    /**
     * @dev withdrawFNFT user can claim their FNFT after the vault period ended
     * ** Params **
     * id IAO event id
     */
    function withdrawFNFT(bytes memory) public{
        _delegatecall(IAOHandler);  
    }

    /**
     * @dev returnFund after the IAO event end, if the assets are not valid, superAdmins can returned fund to buyers
     * ** Params **
     * receivers receivers
     * iaoId iaoId
     */
    function returnFund(
        address[] memory,
        bytes memory
    ) public payable{
        _delegatecall(IAOHandler);
    }

    /**
     * @dev withdrawRevenue owner can claim revenue
     * ** Params **
     * ids IAO event id
     * receiver
     */
    function withdrawRevenue(bytes [] memory, address ) public payable{
        _delegatecall(IAOHandler);
    }

    /**
    *@dev setFractorRevenue admin set the revenue of the IAO event that fractor can claim
    *  iaoId iaoId
    *  revenue fractor revenue
    *  bdRate
    *  platformRate
     */

    function setFractorRevenue(
        bytes memory ,
        uint256,
        uint256,
        uint256 
    ) public  {
        _delegatecall(IAOHandler);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {Upgradeable} from "../common/Upgradeable.sol";
import "../interfaces/IERC20.sol";

contract Implementation is Upgradeable{

    /**
     * @dev setToken721Address
     * ** Params **
     * @param _addr address
     */
    function setToken721Address(address _addr) public onlyOwner {
        require(_addr != address(0), "Controller: The address can not be address 0");
        require(_addr != token721Address, "Controller: The address can not be the old address");
        token721Address = _addr;
    }

    /**
     * @dev setToken721Address
     * ** Params **
     * @param _addr address
     */
    function setSignatureUtils(address _addr) public onlyOwner {
        require(_addr != address(0), "Controller: The address can not be address 0");
        require(_addr != signatureUtils, "Controller: The address can not be the old address");
        signatureUtils = _addr;
    }

    /**
     * @dev setToken721Address
     * ** Params **
     * @param _addr address
     */
    function setIAOHandler(address _addr) public onlyOwner {
        require(_addr != address(0), "Controller: The address can not be address 0");
        require(_addr != IAOHandler, "Controller: The address can not be the old address");
        IAOHandler = _addr;
    }

    /**
     * @dev setToken721Address
     * ** Params **
     * @param _addr address
     */
    function setNFTHandler(address _addr) public onlyOwner {
        require(_addr != address(0), "Controller: The address can not be address 0");
        require(_addr != NFTHandler, "Controller: The address can not be the old address");
        NFTHandler = _addr;
    }


    /**
     * @dev setToken721Address
     * ** Params **
     * @param _addr address
     */
    function setDepositHandler(address _addr) public onlyOwner {
        require(_addr != address(0), "Controller: The address can not be address 0");
        require(_addr != DepositHandler, "Controller: The address can not be the old address");
        DepositHandler = _addr;
    }
        
    /**
     * @dev setSigner
     * ** Params **
     * @param addr address
     */
    function setSigner(address addr) public onlyOwner {
        require(addr != address(0), "Controller: The address can not be address 0");
        require(addr != signer, "Controller: The address can not be the old address");
        signer = addr;
        emit SetSignerEvent(addr);
    }

    /**
     * @dev setAdmin
     * ** Params **
     * @param addr address
     * @param adminRole role
     * @param setBy set by 
     */
    function setAdmin(address addr, uint256 adminRole, string memory setBy, string memory adminId) public onlySuperAdmins {
        require(addr != address(0), "Controller: The address can not be address 0");
        require(!blackList[addr], "Controller: The address was blocked");
        require(adminRole >0, "Controller: Invalid role");
        require(adminRole !=1 || msg.sender == owner(), "Controller: Only Owner can set SuperAdmin");
        role[addr] = adminRole; 
        emit SetAdminEvent(addr, adminRole, setBy, msg.sender, adminId);
    }

        /**
     * @dev revokeAdmin
     * ** Params **
     * @param addr address
     * @param setBy set by 
     */
    function revokeAdmin(address addr, string memory setBy, string memory adminId) public onlySuperAdmins{
        require(addr != address(0), "Controller: The address can not be address 0");
        require(role[addr] > 0, "Controller: The address is not admin");
        require(role[addr] != 1 || msg.sender == owner(), "Controller: Only Owner can revoke SuperAdmin");
        role[addr] = 0; 
        blackList[addr] = true;
        emit SetAdminEvent(addr, 0, setBy, msg.sender, adminId);
    }

    /**
     * @dev getAdminRole
     * ** Params **
     * @param addr address
     */
    function getAdminRole(address addr) public view returns(uint256) {
        if (blackList[addr]) {
            return 0;}
        else if (addr == owner()){
            return 100;
        }
        else{
            return role[addr];}
    }

    /**
     * @dev setBlacklist
     * ** Params **
     * @param addr address
     * @param value bool (true) blacklisted, (false) not blacklisted
     */
    function setBlacklist(address addr, bool value) public onlySuperAdmins{
        blackList[addr] = value;
        emit SetBlacklistEvent(addr, value);
    }

    /**
     * @dev isBlacklisted
     * ** Params **
     * @param addr address
     */
    function isBlacklisted(address addr) public view returns(bool) {
        return blackList[addr];
    }

    /**
     * @dev getNFTsDepositedByFractor 
     * ** Params **
     * @param fractorId fractorId
     */
    function getNFTsDepositedByFractor(bytes memory fractorId) public view returns(
        uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, address[] memory
    ){  
        uint256 leng = len[fractorId];
        uint256[] memory index = new uint256[](leng);
        uint256[] memory tokenIds= new uint256[](leng);
        uint256[] memory nftTypes= new uint256[](leng);
        uint256[] memory tokenAmounts= new uint256[](leng);
        address[] memory collectionAddrs= new address[](leng);
        for (uint256 i = 0; i < len[fractorId]; i++){
            index[i] = i;
            tokenIds[i] = fractorNFT[fractorId][i].tokenId;
            nftTypes[i] = fractorNFT[fractorId][i].nftType;
            tokenAmounts[i] = fractorNFT[fractorId][i].tokenAmount;
            collectionAddrs[i] = fractorNFT[fractorId][i].collectionAddress;
        }
        return (index, tokenIds, nftTypes, tokenAmounts, collectionAddrs);
    }

    /**
     * @dev getFNFTOwned get balance of FNFT 
     * ** Params **
     * @param addr address
     */
    function getFNFTOwned(
        address addr
    ) public view returns(address[] memory, uint256[] memory){
        uint256 leng = fnftLists[0].fnftList.length;
        address[] memory list = new address[](leng); 
        uint256[] memory balance = new uint256[](leng);
        uint256 j = 0;
        for(uint256 i = 0; i < leng; i ++){
                list[j] = fnftLists[0].fnftList[i];
                balance[i] = IERC20(fnftLists[0].fnftList[i]).balanceOf(addr);
                j++;
        }
        return (list, balance);
    }


    function getFNFTListLength() public view returns(uint256){
        return fnftLists[0].fnftList.length;
    }

    /**
     * @dev getFNFTOwnedFor get balance of FNFT  
     * ** Params **
     * @param addr address
     * @param start index
     * @param end index
     */
    function getFNFTOwnedFor(
        address addr,
        uint256 start,
        uint256 end
    ) public view returns(address[] memory, uint256[] memory){
        address[] memory list = new address[](end - start); 
        uint256[] memory balance = new uint256[](end -start);
        uint256 j = 0;
        for(uint256 i = start; i < end; i ++){
                list[j] = fnftLists[0].fnftList[i];
                balance[i] = IERC20(fnftLists[0].fnftList[i]).balanceOf(addr);
                j++;
        }
        return (list, balance);
    }

   
    /**
     * @dev isRevenueAdmin check if the _addr is revenueAdmin 
     * ** Params **
     * @param _addr address
     */
    function isRevenueAdmin(address _addr) public view returns(bool) {
        return _addr == revenueAdmin;
    }

    /**
     * @dev setToken721Address
     * ** Params **
     * @param _addr address
     */
    function setRevenueAdmin(address _addr) public onlyOwner {
        require(_addr != address(0), "Controller: The address can not be address 0");
        require(_addr != revenueAdmin, "Controller: The address can not be the old address");
        revenueAdmin = _addr;
    } 

    /**
     * @dev checkRevenueBalance get fractor 's revenue 
     * ** Params **
     * @param iaoIds iao event ids
     */
    function checkRevenueBalance(bytes [] memory iaoIds) 
    public view returns(address[] memory, uint256[] memory){
        uint256 leng = iaoIds.length;
        address[] memory tokenList = new address[](leng);
        uint256[] memory balanceList = new uint256[](leng);

        for (uint256 i = 0; i < leng; i ++){
            tokenList[i] = iaos[iaoIds[i]].tokenAddr;
            balanceList[i] = fractorRevenue[iaoIds[i]];
        }
        return (tokenList, balanceList);
    }


    /**
     * @dev checkFractorUnmergedFNFT 
     * ** Params **
     * @param fractorId fractorId
     */
    function checkFractorUnmergedFNFT(bytes memory fractorId) public view returns(address[] memory list) {
        uint256 len = fractorFNFT[fractorId].fnftList.length;
        list = new address[](len);
        uint256 j = 0;
        for (uint256 i = 0; i < len; i ++){
            if (IERC20(fractorFNFT[fractorId].fnftList[i]).totalSupply() != 0){
                list[j] = (fractorFNFT[fractorId].fnftList[i]);
                j++;
            }
        }
        return list;
    }
    


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";


contract Upgradeable is Ownable, ReentrancyGuard, IERC721Receiver, ERC1155Receiver{
    address public token721Address;    
    address public signer;
    address public signatureUtils;
    address public IAOHandler;
    address public NFTHandler;
    address public DepositHandler;

    mapping(address => uint256) role; // (1) SuperAdmin (2) OperationAdmin (3) HeadOfBD (4) FractorBD (5) MasterBD
    mapping(address => bool) blackList;
    mapping(bytes => IAO) public iaos;
    mapping(bytes => bool) isClosed; //IAO Event
    mapping(uint256 => bool) nftIsInEvent;

    mapping(bytes =>mapping(address => uint256)) public fundDeposited;
    mapping(bytes =>mapping(address => uint256)) public fnftFromFund;
    mapping(bytes => uint256) public totalFundOfEvent;
    mapping(bytes => uint256) public totalFNFTFromFundOfEvent;


    mapping(bytes => uint256) public len;
    mapping(bytes => mapping(uint256 => DepositedNFT)) public fractorNFT;
    mapping(uint256 => NFT) public NFTs;

    mapping(address => bool) public isDeactivated;
    mapping(bytes => bool) public fractorClaimed;
    mapping(string => bool) public isMinted;
    mapping(bytes => bool) public isSuccessful;
    mapping(bytes => bool) public iaoEventIsDeactivated;
    mapping(address => bool) public isSellingInIAOEvent;
    mapping (string => address) public idToFNFT;
    mapping(bytes => bool) public invalidSignature;
    mapping(uint256 => fnftList) fnftLists;

    mapping(bytes => uint256) public fractorRevenue;
    mapping(bytes => bool) adminClaimed;
    mapping(bytes => uint256) public hardcap;
    mapping(address => bytes) fnftToIAO;
    mapping(bytes => fnftList) fractorFNFT;
    
    address revenueAdmin;
    struct fnftList{
        address[] fnftList;
    }

    
    
    struct IAO {
        uint256 threshold; 
        uint256 startDate;
        uint256 endDate;
        uint256 amount;
        uint256 limit;
        address tokenAddr;
        address fractTokenAddr;
    }

    struct DepositedNFT{
        uint256 tokenId;
        uint256 nftType;
        uint256 tokenAmount;
        address collectionAddress;
    }
    struct  NFT{
        uint256[] tokenIds;
        uint256[] nftTypes;
        uint256[] tokenAmounts;
        address[] collectionAddresses;
        uint256 chainId;
    }

    event SetAdminEvent(address addr, uint256 role, string setBy, address caller, string adminId);
    event SetBlacklistEvent(address addr, bool value);
    event SetSignerEvent(address addr);
    event DepositFundEvent(address buyer, uint256 fund, uint256 tokenAmount, uint256 totalFundDeposited, uint256 totalFNFT ,bytes iaoId, bytes internalTxId);
    event DepositNFTEvent(address sender, address nftAddr, uint256 tokenId, uint256 tokenType, uint256 tokenAmount, bytes fractorId, string assetId, string uri);
    event WithdrawFNFTEvent(address sender, bytes id, uint256 amount);
    event WithdrawFundEvent(address sender, bytes id, uint256 amount);
    event MintNFTEvent(uint256 nftId, uint256 chainId, uint256 [] tokenIds, uint256 [] nftTypes, uint256 [] tokenAmounts, address mintBy, string assetId);
    event MintFNFTEvent(uint256 []tokenIds, uint256 amount, address fracTokenAddr, string name, string symbol, address mintBy, string fnftId, bytes fractorId);
    event FundReturnedEvent(bytes iaoId, address receiver, uint256 amount,address caller, bytes fractorId);
    event ReturnFundEvent(bytes iaoId, address caller);
    event CreateIAOEventEvent(
        bytes iaoId,
        uint256 threshold,
        uint256 startDate,
        uint256 endDate,
        uint256 amount,
        uint256 limit,
        address tokenAddress,
        address fracTokenAddress,
        address createdBy);

    event FractorClaimEvent(
        address receiver,
        uint256[] tokenAmount,
        uint256[] revenue,
        bytes[] iaoId,
        bytes fractorId
    );

    event DeactivateFNFTEvent(address fractTokenAddress, address setBy);
    event DeactivateIAOEvent(bytes iaoId, address caller, address fnftAddr);
    event WithdrawRevenueEvent(bytes iaoId, address receiver, uint256 revenue, address tokenAddress);
    event SetFractorRevenueEvent(bytes iaoId, uint256 revenue, bytes fractorId, address caller, uint256 bdRate, uint256 platformRate);
    event getNFTEvent(address tokenAddr, uint256[] tokenIds, address receiver);
    event redeemNFTEvent(address receiver, address[] collectionAddrs, uint256[] tokenIds, uint256[] nftTypes, uint256[] tokenAmounts, string requestId);
    modifier notBlacklisted(){
        require(!blackList[msg.sender],"Controller: Blocked");
        _;
    }

    modifier onlySuperAdmins(){
        require(msg.sender == owner() || role[msg.sender] == 1,
        "Controller: The caller is not owner or super admin");
        _;
    }

   modifier onlyOperationAdmins(){
        require(msg.sender == owner() || role[msg.sender] == 1 || role[msg.sender] == 2,
        "Controller: The caller is not owner or super admin");
        _;
    }
    

    
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override pure returns (bytes4){
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override pure returns (bytes4){
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override pure returns (bytes4){
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }


    // == COMMON FUNCTIONS == //
    function _delegatecall(address _impl) internal virtual {
        require(
            _impl != address(0),
            "Implementation: impl address is zero address"
        );
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                sub(gas(), 10000),
                _impl,
                0,
                calldatasize(),
                0,
                0
            )
            let size := returndatasize()
            returndatacopy(0, 0, size)
            switch result
            case 0 {
                revert(0, size)
            }
            default {
                return(0, size)
            }
        }
    }

}

// SPDX-License-Identifier: MIT
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

    function burn(
        uint256 amount
    ) external;

    function burnFrom(
        address account,
        uint256 amount
    ) external;

    function fractorId() external returns(bytes memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}