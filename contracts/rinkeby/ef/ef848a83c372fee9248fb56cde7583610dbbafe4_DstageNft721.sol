/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// On Deployment use Specific values for Enums as Like (0,1,2,3)
// Lock Bidder Value
//Nft[nftId].bidAmount[Nft[nftId].index], Nft[nftId].bidderAddress[Nft[nftId].index]
contract DstageNft721Auction {  //is DstageERC20 
    event availableForBids(uint, string) ;
    event removeFormSale (uint, string );
    enum status {NotOnSale ,onAuction, onBidding, OnfixedPrice }
    mapping (address => uint) BidsAmount;
    mapping (address => uint ) BiddingInfo; 

    status public CurrentStatus;
    struct NftDetails{
        uint [] bidAmount;
        address[] bidderAddress;
        // bool IsonSale;
        uint startingPrice;
        uint startTime;
        uint endTime;
        // Using minimum Bid for Fixed Price of NFt and minimum bid in auction and Bididing 
        uint minimumPrice;
        uint index;
        status salestatus;
        mapping(address => bool) hasBidden;
    }

    modifier notOnSale (uint nftId) {
        require(Nft[nftId].salestatus == status.NotOnSale, "Error! Nft is Already on Sale");
        _;
    }
    modifier onBidding(uint nftId){
        require(Nft[nftId].salestatus == status.onBidding, "Error! NFT is Not Available for Biding");
        _;
    }
    modifier onSale (uint nftId) {
        require(Nft[nftId].salestatus == status.onAuction ||  Nft[nftId].salestatus == status.onBidding || Nft[nftId].salestatus == status.OnfixedPrice, "Error! Nft is Not on Sale");
        // require(Nft[nftId].IsonSale == true, "NFT is Not on Sale");
        _;
    
    }
    modifier onAuction(uint nftId){
        require(Nft[nftId].salestatus == status.onAuction, "Nft is Not Available for Auction");
        _;
    }
    modifier onFixedPrice (uint nftId){
        require(Nft[nftId].salestatus == status.OnfixedPrice, "NFT is Not Available for Fixed Price");
        _;
    }
    mapping(uint=>NftDetails) Nft;
    //Biding for Local NFT will be local

    //Place NFT to Accept Bids
    function _placeNftForBids(uint NftId ) notOnSale(NftId) internal {
        CurrentStatus = status(2);
        // NftDetails storage NftDetailobj = Nft[NftId];   I think it will create Storage Obj automatically,  Nft[NftId].salestatus  
        Nft[NftId].salestatus = CurrentStatus;
        emit availableForBids (NftId, "Accepting Bids");
    }

    //  Done 
    function _addOpenBid(uint nftId, uint _bidAmount) onBidding(nftId) internal  {
        _pushBidingValues(msg.sender, nftId, _bidAmount);
        _updateBiddingMapping(msg.sender, _bidAmount);
         _getIndexOfHighestBid(nftId);
        // if (Nft[nftId].bidAmount[Nft[nftId].index] <= _bidAmount ){
        //     Nft[nftId].index= Nft[nftId].bidAmount.length;  // Add Index of that Number
        //     // return Nft[nftId].index;
        // }
        // return Nft[nftId].index;
    }

    function _putNftForTimedAuction(uint nftId, uint startTime, uint endTime, uint minAmount) notOnSale(nftId) internal{
        // start time should be near to Block.timestamp
        require (startTime != endTime && block.timestamp < endTime , "Error! Time Error");
        CurrentStatus = status(1);
        Nft[nftId].salestatus = CurrentStatus;
        Nft[nftId].startTime = startTime;
        Nft[nftId].endTime = endTime;
        Nft[nftId].minimumPrice = minAmount;
        emit availableForBids (nftId, " Accepting Bids");
    }

    //it is Time Based Auction
    function _addAuctionBid(uint nftId, uint _bidAmount) onAuction(nftId) internal{
        // Check is time remaining to Bid
        require(block.timestamp <= Nft[nftId].endTime, "Time is Overed");
        _pushBidingValues(msg.sender, nftId, _bidAmount);
        _updateBiddingMapping(msg.sender, _bidAmount);
        Nft[nftId].hasBidden[msg.sender]=true;
        _getIndexOfHighestBid(nftId);
    }

    // function putOnSale(uint NftId) internal {
    //     require(Nft[NftId].IsonSale == false, "Not On Sale");
    //     Nft[NftId].IsonSale = true;
    // }
    function _pushBidingValues (address _address, uint nftId, uint _bidAmount) internal{
        Nft[nftId].bidAmount.push(_bidAmount);
        Nft[nftId].bidderAddress.push(_address);
    }
    function _putNftForFixedPrice(uint nftId, uint Fixedamount ) notOnSale(nftId) internal{
        CurrentStatus = status(3);
        Nft[nftId].salestatus = CurrentStatus;
        Nft[nftId].minimumPrice = Fixedamount;
    }
    // Pending Indexing
    function GetHighestIndexvalue(uint nftId) external onAuction(nftId) view returns(bool, uint , address ){
        if(Nft[nftId].salestatus != status.onAuction &&  Nft[nftId].salestatus != status.onBidding)
            return (false, 0,address(0));
        else
            return (true, Nft[nftId].bidAmount[Nft[nftId].index], Nft[nftId].bidderAddress[Nft[nftId].index]);
    }
    function _removeFromSale(uint nftId) onSale(nftId) internal { 
        CurrentStatus = status(0);
        Nft[nftId].salestatus = CurrentStatus;
        emit removeFormSale(nftId , "Error! NFT is removed from Sale ");
    }
    function CheckNftStatus(uint nftId) view external returns(status){
        return Nft[nftId].salestatus;
    }
    // For Testing
    function _getIndexOfHighestBid(uint nftId) internal returns (uint){
        uint temp = 0;
        for (uint i=0; i<Nft[nftId].bidAmount.length; i++){
            if (temp<Nft[nftId].bidAmount[i])
            {
                temp = Nft[nftId].bidAmount[i];
                Nft[nftId].index = i;
            }
        }
        return Nft[nftId].index;
    }

    function checkExistance(uint tokenID) public view returns(bool){}
    // For testing 
    // function getHighestBid(uint nftId) external view onAuction(nftId) returns(uint){
    //     // require(_exists(nftId), "Nft Does Not Exists");
    //     // _getIndexOfHighestBid(nftId);
    //     return Nft[nftId].bidAmount[Nft[nftId].index];
    // }
    function _updateBiddingMapping(address _address , uint _biddingAmount) internal {
        BidsAmount[_address] += _biddingAmount;
        
    }
    function _extendAuctionTime (uint _nftId, uint _endTime) onAuction(_nftId) internal{
        require(_endTime > Nft[_nftId].endTime && Nft[_nftId].endTime < block.timestamp , "Time Reset Error!");
        Nft[_nftId].endTime = _endTime;
    }
    function _releaseBiddingValue(uint nftId) internal {
        for (uint i=0; i<Nft[nftId].bidderAddress.length; i++){
            BidsAmount[Nft[nftId].bidderAddress[i]] -= Nft[nftId].bidAmount[i];
        }
    }
}
// File: Dstage-ethereum-contracts/contracts/Dstage721/IERC2981Royalties.sol


pragma solidity ^0.8.0;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)external view returns (address _receiver, uint256 _royaltyAmount);
}
// File: Dstage-ethereum-contracts/contracts/Dstage721/ERC2981Base.sol


pragma solidity ^0.8.0;


/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981Base is IERC2981Royalties {   //ERC165,
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

}
// File: Dstage-ethereum-contracts/contracts/Dstage721/ERC2981PerTokenRoyalties.sol


pragma solidity ^0.8.0;


/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981PerTokenRoyalties is ERC2981Base {
    mapping(uint256 => RoyaltyInfo) internal _royalties;

    /// @dev Sets token royalties
    /// @param tokenId the token id fir which we register the royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setTokenRoyalty(
        uint256 tokenId,
        address recipient,
        uint256 value
    ) internal {
        require(value <= 10000, 'ERC2981Royalties: Too high');
        _royalties[tokenId] = RoyaltyInfo(recipient, uint24(value));
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256 tokenId, uint256 value)external view override returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalties = _royalties[tokenId];
        receiver = royalties.recipient;
        royaltyAmount = (value * royalties.amount) / 10000;
    }
    
}

// File: Dstage-ethereum-contracts/contracts/Dstage721/DstageNft721Royalties.sol


pragma solidity ^0.8.0;

contract Dstage721Royalties{
    // uint public DstageFees;
    event RoyaltiesTransfer (uint DstageFee, uint minterFee, uint nftSellerAmount) ;
    struct RoyaltyInfo {
        address payable recipient;
        uint24 amount;
    }
    mapping(uint256 => RoyaltyInfo) internal _royalties;

    // mapping (address=>bool) DstageWhiteList;

    mapping (address=>uint) _deposits;

    function _getBidBalance(address payable payee, uint bidAmount) internal{
        require(msg.value >= bidAmount, "Insufficient balance");
        _deposits[payee] += bidAmount;  
    }
    function checkBalance(address _address) public view returns(uint ){
        return _deposits[_address];
    }
    function _withdrawBalance( uint amount ) internal {
        //  Check Owner
        //  Check is on Bidding
        //  require(msg.sender == _deposits);
        require (amount != 0 && amount <= _deposits[msg.sender], "Error! Amount is zero or Low Balance");
        _deposits[msg.sender]-= amount; 
        payable(msg.sender).transfer(amount);
    }
    function _deductBiddingAmount(uint _bidAmount, address highestBidderAddress) internal {
        require(_deposits[highestBidderAddress] >= _bidAmount, "Error! Insifficent Balance");
        _deposits[highestBidderAddress]-= _bidAmount;
    }

    function _setTokenRoyalty(uint256 tokenId,address payable recipient,uint256 value) internal {
        require(value <= 10000, "ERC2981Royalties: Too high");
        _royalties[tokenId] = RoyaltyInfo(recipient, uint24(value));
    }
    
    
    /* this Function will be Called only in transfer function so its internal
    ** While Transfering a token Royalties will be deducted
    ** 1) Get Balance in Contract   2)Deduct Dstage percentage 3) Deduct Amount for 1st Minter   
    */
    function _royaltyAndDstageFee (uint _NftPrice, uint percentage, address payable minterAddress, address payable NftSeller) internal {
        uint _TotalNftPrice = _NftPrice;
        uint _DstageFee = _deductDstageFee(_NftPrice);
        uint _minterFee = _SendMinterFee(_NftPrice , percentage,  minterAddress);
        //Remaining Price After Deduction  
        _TotalNftPrice = _TotalNftPrice - _DstageFee - _minterFee;
        // Send Amount to NFT Seller after Tax deduction
        _transferAmountToSeller( _TotalNftPrice, NftSeller);
        emit RoyaltiesTransfer (_DstageFee, _minterFee, _TotalNftPrice);
    }
    
    function _deductDstageFee(uint Price) internal pure returns(uint) {
        require((Price/10000)*10000 == Price, "Error! Too small");
        return Price*25/1000;
    }

    function _transferAmountToSeller(uint amount, address payable seller) internal {
        seller.transfer(amount);
    }
    
       // Deduct Minter Fee
    function _SendMinterFee(uint _NftPrice, uint Percentage, address payable recepient)  internal returns(uint) {
        //Calculate Minter percentage and Send to his Address from Struct
        uint AmountToSend = _NftPrice*Percentage/100;
        // Send this Amount To Transfer Address from Contract balacne 
        recepient.transfer(AmountToSend);
        return AmountToSend;
    }   

}
// File: Dstage-ethereum-contracts/contracts/Dstage721/Strings.sol


// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
// File: Dstage-ethereum-contracts/contracts/Dstage721/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// File: Dstage-ethereum-contracts/contracts/Dstage721/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// File: Dstage-ethereum-contracts/contracts/Dstage721/Address.sol


// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
// File: Dstage-ethereum-contracts/contracts/Dstage721/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

// import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    // function tokenURI(uint256 tokenId) external view returns (string memory);
}
// File: Dstage-ethereum-contracts/contracts/Dstage721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
// File: Dstage-ethereum-contracts/contracts/Dstage721/IERC721.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

}
// File: Dstage-ethereum-contracts/contracts/Dstage721/ERC721.sol


pragma solidity ^0.8.0;







contract ERC721 is Context ,IERC721, IERC721Metadata { 
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }


    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }


    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn721(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    // function totalSupply() internal returns (uint){
    //     return _owners[uint].length();
    // }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}
// File: Dstage-ethereum-contracts/contracts/Dstage721/ERC721URIStorage.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;


/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    // Return base URI with Token ID
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    // After Publishing Data On IPFS then Hashed Value will Send in this Function through Mint
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal   {
        ERC721._burn721(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}
// File: Dstage-ethereum-contracts/contracts/Dstage721/Dstage721Base.sol


pragma solidity ^0.8.0;






contract DstageNft721 is ERC721, Ownable, ERC721URIStorage, Dstage721Royalties, DstageNft721Auction{
    modifier IsApprovedOrOwner(uint nftId) {
        require (_isApprovedOrOwner(_msgSender(), nftId), "Error! Only owner has Access");
        _;
    }
    modifier ActiveSale() {
        require (saleIsActive == true, "Sale is Not Active");
        _;
    }

    bool public saleIsActive = false;
    string public provenanceHashValue;
    mapping (uint=>uint) private NFT_Price;
    // NFT ID to 1st Minter Address  
    mapping (uint => address) MinterAddress; 
    constructor (string memory name, string memory symbol) ERC721(name, symbol){}
    
    function checkNftPrice(uint nftId) public view returns(uint){
        require(_exists(nftId), "Error! Token ID Does't Exist");
        return NFT_Price[nftId];
    }

    function MintTo(address payable to, uint tokenId, string memory TokenURI , address payable localMinter, uint Percentage, uint NftPrice) public payable { 
        require(saleIsActive, "Error! Sale is Not Active");
        require(msg.value >= NftPrice , "Error! Insufficient Balance");
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, TokenURI);
        // Adding in Mapping to Struct through below .
        _setTokenRoyalty(tokenId, payable(localMinter), Percentage); // Setting Address of local minter for royalty on each transfer and Percentage what he has decided 
        //Storing NFT Price
        NFT_Price[tokenId]= msg.value;
        _royaltyAndDstageFee(NftPrice, Percentage, localMinter, localMinter );
    }

    function _simpleMint (uint tokenId, string memory tokenURI, uint minterPercentage) public { // , uint NftPrice  Add Nft Price Here
        require(saleIsActive, "Error! Sale is Not Active");
        require(minterPercentage <= 50, "Error! Maximum Minting Percentage is 50% ");
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);
        _setTokenRoyalty(tokenId, payable(msg.sender), minterPercentage);
        // NFT_Price[tokenId] = NftPrice;
    }
    function MintForTimedAuction (uint NftId, string memory tokenURI, uint minterPercentage, uint startTime, uint endTime, uint minimumAmount) public { // , uint NftPrice  Add Nft Price Here
        _simpleMint(NftId , tokenURI , minterPercentage);
        _putNftForTimedAuction(NftId, startTime, endTime, minimumAmount);
    }
    function MintForOpenBidding (uint NftId, string memory tokenURI, uint minterPercentage) public { // , uint NftPrice  Add Nft Price Here
        _simpleMint(NftId , tokenURI , minterPercentage);
        _placeNftForBids(NftId);
    }
    function MintForFixedPrice (uint NftId, string memory tokenURI, uint minterPercentage, uint fixedPrice) public { // , uint NftPrice  Add Nft Price Here
        _simpleMint(NftId , tokenURI , minterPercentage);
        PlaceNftForFixedPrice(NftId , fixedPrice );
    }
    function switchSaleState() public onlyOwner{
        if (saleIsActive == true){
            saleIsActive = false;
        }
        else{
            saleIsActive = true;
        }
    }
    function SafeTransferFromDstage (address payable from, address payable to, uint tokenId, bytes memory data) external {
        _safeTransferFromDstage(from, to, tokenId, data);
    }
    function _safeTransferFromDstage(address payable from, address payable to, uint tokenId, bytes memory data) internal {
        _updateNftPrice(tokenId);
        RoyaltyInfo memory royalties = _royalties[tokenId];
        _royaltyAndDstageFee(NFT_Price[tokenId], royalties.amount, royalties.recipient, payable(_owners[tokenId]));
        _safeTransfer(from, to, tokenId, data);
    }
    
    function transferFromDstage(address payable from, address payable to, uint tokenId) payable external {
        _updateNftPrice( tokenId);
        RoyaltyInfo memory royalties = _royalties[tokenId];
        _royaltyAndDstageFee(NFT_Price[tokenId], royalties.amount, royalties.recipient, payable(_owners[tokenId]));
        _transfer(from, to, tokenId);
        // NFT_Price[tokenId]=msg.value;
    }
    function _updateNftPrice(uint tokenId) internal  {
        require (msg.value >= NFT_Price[tokenId], "Amount is Less then NftPrice");
        NFT_Price[tokenId]=msg.value;
    }
    function getBalanceContract() public view onlyOwner returns(uint){
        return address(this).balance;
    }
    function BurnTokken(uint tokenID) IsApprovedOrOwner(tokenID) public {
       ERC721URIStorage._burn(tokenID);        
    }
    // Function Place NFT for Bidding
    function PlaceNftForOPenBidding(uint NftId) ActiveSale IsApprovedOrOwner(NftId) external  {
        _placeNftForBids(NftId);
    }
    function PlaceNftForTimedAuction(uint NftId, uint startTime,uint endTime, uint minimumAmount) ActiveSale IsApprovedOrOwner(NftId) external  {
        _putNftForTimedAuction(NftId, startTime, endTime, minimumAmount);
    }

    function AddOpenBids(uint nftId , uint _bidAmount) external payable {
        if (_deposits[msg.sender] < _bidAmount){
            _getBidBalance(payable(msg.sender), _bidAmount);
        }
        require(_bidAmount <= _deposits[msg.sender], "Error! Insufficient Balance");
        _addOpenBid( nftId, _bidAmount);
    }
    function AddAuctionBid(uint nftId, uint _bidAmount) public payable {
        require(Nft[nftId].hasBidden[msg.sender]==false, "Only 1 Bid is allowed per Wallet");
        if(Nft[nftId].bidAmount.length != 0)
            require(_bidAmount >= (Nft[nftId].bidAmount[Nft[nftId].index] + (Nft[nftId].bidAmount[Nft[nftId].index]*10)/100), "Bid Amount Must be greater than 10% of current Highest Bid");
        if (_deposits[msg.sender] < _bidAmount){
            _getBidBalance(payable(msg.sender), _bidAmount);
        }
        require( _bidAmount >= Nft[nftId].minimumPrice && _bidAmount <= _deposits[msg.sender], "Error! Insufficient Balance or Low Biding Amount");
        _addAuctionBid(nftId,_bidAmount);
    }
    /*************************************OPEN BIDDING************************************/
    function AcceptYourHighestBid (uint nftId) IsApprovedOrOwner(nftId) external  {
        _getIndexOfHighestBid(nftId);
        _deductBiddingAmount(Nft[nftId].bidAmount[Nft[nftId].index], Nft[nftId].bidderAddress[Nft[nftId].index]);   // Deduct Bidder Amount of Bidding 
        _royaltyAndDstageFee (Nft[nftId].bidAmount[Nft[nftId].index], _royalties[nftId].amount, _royalties[nftId].recipient, payable(ownerOf(nftId)) );
        _transfer(_owners[nftId], Nft[nftId].bidderAddress[Nft[nftId].index], nftId);
        _setNftPrice(nftId, Nft[nftId].bidAmount[Nft[nftId].index]);
        _removeNftFromSale(nftId);
    }
    function _setNftPrice(uint nftId, uint nftPrice) internal {
        NFT_Price[nftId] = nftPrice;
    }
    function PlaceNftForFixedPrice(uint nftId , uint Fixedprice ) ActiveSale IsApprovedOrOwner(nftId) public {
        require(_exists(nftId), "Nft Does Not Exist");
        _putNftForFixedPrice( nftId , Fixedprice);
        NFT_Price[nftId] = Fixedprice;
    }
    function RemoveNftFromSale(uint nftId) IsApprovedOrOwner(nftId) external {
        _removeNftFromSale(nftId);
    }
    function _removeNftFromSale(uint nftId) internal {
        require(_exists(nftId), "Nft Does Not Exists");
        _removeFromSale(nftId);
        _releaseBiddingValue (nftId);
    }
    function PurchaseNftFromFixedPrice(uint nftId, address payable to , bytes memory data ) payable external{
        require(msg.value == NFT_Price[nftId], "Error! Insifficient Price" );
        _safeTransferFromDstage(payable(_owners[nftId]),  to, nftId, data);
        // Remove from Fixed Price
        _removeNftFromSale(nftId);
    }
    function WithDrawAmount(uint amount) external {
        require (amount <= _deposits[_msgSender()]-BidsAmount[_msgSender()], "Balance is low and reserved for Bids");
        _withdrawBalance(amount);
    } 
    function placeBidOnLazyMintedNFT(address lazyMinter, uint minimumAmount, uint bidAmount,  uint minterPercentage, uint tokenId, string memory tokenURI, uint startTime, uint endTime ) public payable {
        require(saleIsActive, "Error! Sale is Not Active");
        require(minterPercentage <= 50, "Error! Maximum Minting Percentage is 50% ");
        _safeMint(lazyMinter, tokenId);
        _setTokenURI(tokenId, tokenURI);
        _setTokenRoyalty(tokenId, payable(lazyMinter), minterPercentage);
        _putNftForTimedAuction(tokenId,startTime, endTime, minimumAmount);
        AddAuctionBid(tokenId, bidAmount);
    }
    function extendAuctionTime(uint nftId, uint endTime )  IsApprovedOrOwner(nftId) external{
        _extendAuctionTime(nftId, endTime);
    }
}