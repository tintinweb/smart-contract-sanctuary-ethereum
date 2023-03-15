// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import './interfaces/IMadMonkeySeaClub.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
//Mad Monkey Sea Club Rewards. 
//The royalty payment is based on the Volume generated in the current month
//Each transfer of ETH on the contract which corresponds to 70% of the volume generated monthl
// on opensea or other marketplaces, can be withdrawn by the holders in 
// based on the calculation of the percentage given by the balance divided by the supply

contract MMSC_Rewards is Ownable,ReentrancyGuard {
    uint _levelPay =0; //Payment level active
    uint public NftmmscSupply = 7999;
    address contractNFT;
    address public contractDAO;
    uint public maxNftinWalletToPay = 20; //maximum number of NFTs in Wallet
    uint256 private _perc_of_LevelPay = 0;//payout percentage for outstanding NFTs
    bool public contractPause = false; //Contract block
    address private ownerContract = 0x5365244D3557d6FA2e72bc6Abd979229d9C215cA; //Owner contract MMSC Rewards 

    struct PaymentStep 
    {
        uint levelPay;
        uint256 amounttransfered;
        uint256 Perc_of_LevelPay; //amount of payment for each NFT
    }
    PaymentStep[] public _paymentstep; 
    struct MadMonkeyTokenID{
        uint tokenId;
    }
    MadMonkeyTokenID[] public _tokenidpayed; 
    
    //contract can receive ETH from ownerContract,
    // set levelPay 0 and it waiting the first transaction to activate level 1 distribution
    constructor(address _contractNFT) payable { 
        _levelPay = 0;
        contractPause = false;
        contractNFT = _contractNFT;
    }
    //When the contract receives a payment it creates a payment level 
    //for the holders that they can receive ETH with ClaimHolderProfit function 
    receive() payable external onlyOwner nonReentrant{
        require(!contractPause, "MadMonkeySeaClub Payment splitter is sleepping!");
         _levelPay = _levelPay+1;
        uint256 perc = Calculate_perc_of_LevelPay(msg.value);
        PaymentStep memory newPayment = PaymentStep(_levelPay, msg.value,perc);
        _paymentstep.push(newPayment);
        //delete all payment level 
        delete _tokenidpayed;
    }
   
    //from this function the holders can withdraw their percentage of earnings
    function claimHolderProfit(address MadMonkeyAddress) external payable
    {  
        require(!contractPause, "MadMonkeySeaClub Payment splitter is sleepping!");
        uint holderNftCount = balanceOfNft(MadMonkeyAddress);
        require(holderNftCount>0, "You must purchase a Mad Monkey token to get paid!");
        //Control on the number of nft owned
        require(holderNftCount<=maxNftinWalletToPay, "You have too many Mad Monkeys in your wallet check maxNftinWalletToPay!");
        bool checkToken =false;
        //Calculate % of fee to pay per il numer di nft
       
        uint256 amount = PaymentAmount(_levelPay);
    
        uint256 amountTot = 0;
        uint [] memory tokenId = getTokenIds(MadMonkeyAddress);
     
        //CHECK IF IT HAS ALREADY BEEN PAID
        for (uint a=0; a<tokenId.length; a++)
        {
            checkToken = CheckTokenid(tokenId[a]);
            if (!checkToken)
            {
                addMadMonkey(tokenId[a]);
                 //Calculate the value to be transferred according to the number of NFTs in the wallet
                amountTot = amountTot + amount;
            }
        }
        //the sum of the total payable must be greater than 0
        require(amountTot>0,"You have already been paid for your Mad Monkeys in this payment tier");
        (bool os, ) = payable(MadMonkeyAddress).call{value: amountTot}('');
        require(os);
       
    }
    function CheckTokenid(uint _tokenId) public view returns(bool){

        bool trovato = false;
        for (uint i = 0; i < _tokenidpayed.length; i++) {
           
            if (_tokenidpayed[i].tokenId== _tokenId)
            {
                trovato = true;
                break;
            }
        }
       
        return trovato;
    }
   
    //Counts the number of Tokens paid
    function CountMadMonkey() public view returns(uint){

        return _tokenidpayed.length;
    }
     //ADDING AND READING OF PAYMENT LEVELS
     //Returns the currently active payout level and the percentage to distribute
    function PaymentActive() external view returns (uint)
    {
        return _levelPay;
    }
    //Returns the currently active payout level, the percentage to distribute and the total transferred
    function PaymentStepActive(uint _levelPayread) public view returns (uint,uint256,uint256)
    {
        PaymentStep memory paymentToReturn = _paymentstep[_levelPayread-1];
        return (paymentToReturn.levelPay,paymentToReturn.amounttransfered, paymentToReturn.Perc_of_LevelPay);
    }
    
    function PaymentAmount(uint _levelPayread) public view returns (uint256)
    {
        if (_levelPayread>0)
        {
            PaymentStep storage paymentToReturn = _paymentstep[_levelPayread-1];
            return ( paymentToReturn.Perc_of_LevelPay);
        }
        else 
        {
            return 0;
        }
    }
    
    //Set the contract to pause, function in case of malfunctions
    function setPaused() public onlyOwner {
        contractPause = !contractPause;
    }
    //Set how many maximum NFTs you can have in the Wallet to get paid
    //This will allow you not to be left with too many NFTs in your portfolio and to continue listing a part of them
    function setmaxNftinWalletToPay(uint _maxNftinWalletToPay) external onlyOwner{
      
        maxNftinWalletToPay = _maxNftinWalletToPay;
    }
     //After the withdrawal period for owners the remaining total will be transferred to the DAO contract
     //If all the ETHs are not withdrawn within the 15 days envisaged from the first transfer,
     //they will be transferred to the DAO contract in order to allow holders how to invest them
   function setContractDAO(address _contractDAO) external onlyOwner{
       
        contractDAO = _contractDAO;
    }
    //Return balance of contract
    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }
    //The payment level is set automatically each time ETH is received on the contract,
    // each payment will be divided by the number of NFTs in the collection
    function setlevelPay(uint __levelPay) external onlyOwner
    {
        _levelPay = __levelPay;
    }
   
    //CONTRACT NFT INTERNAL FUNCTION
    function addMadMonkey(uint tokenId) internal  {
         MadMonkeyTokenID memory newPayment = MadMonkeyTokenID(tokenId);
        _tokenidpayed.push(newPayment);
    }
    //Returns the currently active payout percentage
    function Calculate_perc_of_LevelPay(uint256 amount) internal view returns (uint256 perc)
    {
        //Calculation of percentage is based on Amount / the number of NFTs
        perc = amount / NftmmscSupply;
        return perc; 
    }
    function balanceOfNft(address bbof) public view returns (uint256 balance){
        IMadMonkeySeaClub NftContractMMSC = IMadMonkeySeaClub(contractNFT);
        balance =  NftContractMMSC.balanceOf(bbof);
        return balance;
    }
    //Returns obsessed tokens to check that they haven't already been paid for the current level
    function getTokenIds(address _owner) public view returns (uint[] memory) {
       uint256 balance_1 = balanceOfNft(_owner);
       uint256[] memory result = new uint256[](balanceOfNft(_owner));
       uint j = 0;
       for (uint i=1; i<NftmmscSupply; i++)
       {
            address ownerRead = ownerOf(i);
            if (ownerRead == _owner)
            {
                result[j] = i;
                j++;
                if (j == balance_1)
                break;
            }
       }
       return result;
    }
    function ownerOf(uint256 tokenId) public view returns (address owner){
        IMadMonkeySeaClub NftContractMMSC = IMadMonkeySeaClub(contractNFT);
        owner =  NftContractMMSC.ownerOf(tokenId);
        return owner;
    }
    //After the withdrawal period for owners the remaining total will be transferred to the DAO contract
    function withdraw() public onlyOwner nonReentrant {
   
        require(contractDAO!=address(0),"Set Contract DAO");
        (bool os, ) = payable(contractDAO).call{value: address(this).balance}('');
        require(os);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
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

pragma solidity ^0.8.9;

interface IMadMonkeySeaClub  {
    function balanceOf(address owner) external view returns (uint256 balance);
    
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

   
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);

    function totalSupply() external view returns (uint256);
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